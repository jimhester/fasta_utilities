{

  package ReadFastx;
  use Class::XSAccessor getters => [qw(fh files)];
  use Carp;
  use FileBar;

  our $VERSION = '0.20';

  sub new {
    my $class = shift;
    if (@_ == 1 && !ref $_[0]) {
      return bless {files => [$_[0]]}, $class;
    }
    my $self = bless {@_}, $class;
    $self->{files} = \@ARGV unless exists $self->{files};
    $self->BUILD($self);
    return $self;
  }

  sub BUILD {
    my ($self) = @_;
    unless ($self->{fh}) {

      #automatically unzip gzip and bzip files
      @{$self->{files}} = map {
        s/(.*\.gz)\s*$/pigz -dc < $1|/;
        s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;
        $_
      } @{$self->files};

      #if no files read from stdin
      $self->{files} = ['-'] unless @{$self->files};

    }
    $self->{file_itr} = 0;
    $self->current_file($self->files->[0]);
  }

  sub current_file {
    my ($self, $file) = @_;
    if ($file) {
      $self->_set_current_file($file);
    }
    else {
      return exists $self->{current_file} ? $self->{current_file} : undef;
    }
  }

  sub next_file {
    my ($self) = @_;
    $self->{file_itr}++;
    return if $self->{file_itr} >= @{$self->files};
    $self->current_file($self->files->[$self->{file_itr}]);
  }

  sub next_seq {
    my ($self) = @_;
    return &{$self->{reader}};
  }

  sub _set_current_file {
    my ($self, $file) = @_;
    open my $fh, $file or croak "$!: Could not open $file\n";
    $self->{fh} = $fh;
    if (not $self->{bar}) {
      $self->{bar} = FileBar->new(current_file => $file,
                                    files        => $self->files,
                                    fh_in        => $self->fh);
      }
      else {
        $self->{bar}->fh_in($fh);
        $self->{bar}->current_file($file);
    }
    my $first_char = getc $self->{fh};
    $self->{reader} =
        $first_char eq ">" ? sub { $self->_read_fasta }
      : $first_char eq "@" ? sub { $self->_read_fastq }
      :                      croak "Not a fasta or fastq file, $first_char is not > or @";
    $self->{current_file} = $file;
  }

  sub _read_fasta {
    my ($self) = @_;
    local $/ = ">";
    if (defined(my $record = readline $self->{fh})) {
      chomp $record;
      my $newline = index($record, "\n");
      if ($newline > 1) {
        my $header = substr($record, 0, $newline);
        my $sequence = substr($record, $newline + 1);
        $sequence =~ tr/\n\r\t //d;
        my $record = ReadFastx::Fasta->new();
        $record->{header}   = $header;
        $record->{sequence} = $sequence;
        return $record;
      }
    }
    if ($self->_end_of_files()) {
      return undef;
    }
    $self->next_file();
    return $self->next_seq;
  }

  sub _read_fastq {
    my ($self) = @_;
    my $fh = $self->fh;
    my ($header, $sequence, $h2, $quality);

    #ugly for performance I am sorry
    {
      local $/ = "\n";
      $header = readline $fh;
      last unless $header;
      chomp $header;

      $/        = "\n+";
      $sequence = readline $fh;
      last unless $sequence;
      chomp $sequence;

      $/  = "\n";
      $h2 = readline $fh;
      last unless $h2;

      $/       = "\n@";
      $quality = readline $fh;
      last unless $quality;
      chomp $quality;
    }

    if (defined $header and defined $sequence and defined $quality) {
      $sequence =~ tr/\n\r\t //d;
      $quality =~ tr/\n\r\t //d;
      return
        ReadFastx::Fastq->new(header   => $header,
                              sequence => $sequence,
                              quality  => $quality);
    }
    if ($self->_end_of_files()) {
      return undef;
    }
    $self->next_file();
    return $self->next_seq;
  }

  sub _end_of_files {
    my ($self) = @_;
    return (eof $self->{fh} and $self->{file_itr} > @{$self->{files}});
  }

}

{

  package ReadFastx::Fastx;
  use Class::XSAccessor constructor => 'new', accessors => [qw(header sequence)];

  sub _wrap {
    my ($self, $string, $width) = @_;
    if ($width) {
      my $out = '';
      my $cur = 0;
      while ($cur < length($string)) {
        $out .= substr($string, $cur, $width) . "\n";
        $cur += $width;
      }
      return $out;
    }
    return $string, "\n";
  }
}

{

  package ReadFastx::Fasta;
  use base qw(ReadFastx::Fastx);
  use Readonly;

  Readonly my $PRINT_DEFAULT_FH => \*STDOUT;

  sub print {
    my ($self) = shift;
    my $args  = @_ == 1 && ref $_[0]  ? $_[0]          : {@_};
    my $fh    = exists $args->{fh}    ? $args->{fh}    : $PRINT_DEFAULT_FH;
    my $width = exists $args->{width} ? $args->{width} : undef;
    print $fh ">", $self->{header}, "\n", $self->_wrap($self->{sequence}, $width);
  }
}

{

  package ReadFastx::Fastq;
  use base qw(ReadFastx::Fastx);
  use Class::XSAccessor accessors => [qw(is_phred64)];
  use Readonly;

  Readonly my $PRINT_DEFAULT_FH => \*STDOUT;
  Readonly my $ILLUMINA_OFFSET  => 64;
  Readonly my $SANGER_OFFSET    => 32;

  sub quality_array {
    my ($self, $new) = @_;
    if (defined $new) {
      $self->{quality_array} = $new;
      delete $self->{quality};
    }
    elsif (not exists $self->{quality_array}) {
      my $offset = $self->is_phred64 ? $ILLUMINA_OFFSET : $SANGER_OFFSET;
      $self->{quality_array} = [map { $_ - $offset } unpack "c*", $self->quality];
    }
    return $self->{quality_array};
  }

  sub quality {
    my ($self, $new) = @_;
    if (defined $new) {
      $self->{quality} = $new;
      delete $self->{quality_array};
    }
    elsif (not exists $self->{quality}) {
      my $offset = $self->is_phred64 ? $ILLUMINA_OFFSET : $SANGER_OFFSET;
      $self->{quality} = pack "c*", map { $_ + $offset } @{$self->{quality_array}};
    }
    return $self->{quality};
  }

  sub quality_at {
    my ($self, $position, $new) = @_;
    die "quality_at must specify a position" unless defined $position;
    if (defined $new) {
      $self->quality_array()->[$position] = $new;
      delete $self->{quality};
    }
    return $self->quality_array()->[$position];
  }

  sub print {
    my ($self) = shift;
    my $args   = @_ == 1 && ref $_[0]  ? $_[0]            : {@_};
    my $fh     = exists $args->{fh}    ? $args->{fh}      : $PRINT_DEFAULT_FH;
    my $offset = $self->is_phred64    ? $ILLUMINA_OFFSET : $SANGER_OFFSET;
    my $width  = exists $args->{width} ? $args->{width}   : undef;
    print $fh "@", $self->header, "\n", $self->_wrap($self->sequence, $width), "+", $self->header, "\n", $self->_wrap($self->quality, $width);
  }
}

#use namespace::autoclean;
1;
