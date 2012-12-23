{

  package ReadSam;
  use Class::XSAccessor getters => [qw(fh files header)];
  use Carp;
  use FileBar;
  use Readonly;

  Readonly my @SAM_FIELDS => qw(qname flag rname position mapq cigar rnext pnext tlen sequence quality optional);
  our $VERSION = '0.10';

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
    my $self = shift;
    unless ($self->{fh}) {

      #pipe bam files through samtools
      @{$self->{files}} = map {
        s/(.*\.bam)\s*$/samtools view -h $1|/;
        $_
      } @{$self->{files}};

      #if no files read from stdin
      $self->{files} = ['-'] unless @{$self->{files}};
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

  sub next_align {
    my $self = shift;
    unless (eof $self->fh) {
      my $line = readline $self->fh;
      my $parse = $self->parse_align($line);
      my $prev  = $self->{prev};
      $self->{prev} = $parse;
      return $prev;
    }
    else {    #at eof
      if (exists $self->{prev}) {
        my $prev = $self->{prev};
        delete $self->{prev};
        return $prev;
      }
      return unless $self->{file_itr} >= @{$self->{files}};
      $self->next_file();
      return $self->next_align;
    }
  }

  sub parse_align {
    my ($self, $line) = @_;
    my $itr = 0;
    for my $value (split /[\t\n]/, $line) {
      $ref{$SAM_FIELDS[$itr]} = $value;
      $itr++;
    }
    $ref{raw} = $line;
    return ReadSam::SamAlignment->new(%ref);
  }

  sub parse_header {
    my ($self, $headers) = @_;
    my %tags;
    for my $line (split /[\r\n]+/, $headers) {
      my ($code, @tags) = split /\t/, $line;
      $code =~ s/^@//;
      if ($code eq $COMMENT_CODE) {
        push @{$tags{$COMMENT_CODE}}, {Comment => join("\t", @tags)};
      }
      else {
        my %code_tags;
        for my $tuple (@tags) {
          my ($tag, $value) = split /:/, $tuple;
          $code_tags{$tag} = $value;
        }
        push @{$tags{$code}}, \%code_tags;
      }
    }
    return ReadSam::SamHeader->new(tags => \%tags, raw => $headers);
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
    my $line = readline $fh;
    my $headers;
    while ($line =~ /^@/) {
      $headers .= $line;
      $line = readline $fh;
    }
    my $parse = $self->parse_align($line);
    $self->{prev} = $parse;
    if ($headers) {
      $self->{header} = $self->parse_header($headers);
    }
    $self->{current_file} = $file;
  }
}

{

  package ReadSam::SamHeader;
  use Class::XSAccessor constructor => 'new', getters => [qw(raw)], accessors => [qw(tags)];
  use Readonly;

  Readonly my $COMMENT_CODE => 'CO';

  sub lines {
    my $self = shift;
    my $lines;
    for my $code (keys %{$self->tags}) {
      for my $item (@{$self->tags->{$code}}) {
        my $line = $code;
        if ($code eq "COMMENT_CODE") {
          $line .= "\t" . $self->tags->{$code}{$item}{Comment};
        }
        else {
          for my $tag (keys %{$item}) {
            $line .= "\t" . $tag . ":" . $item->{$tag};
          }
        }
        $lines .= "$line\n";
      }
    }
  }
}

{

  package ReadSam::SamAlignment;
  use Readonly;

  Readonly my $PRINT_DEFAULT_FH => \*STDOUT;
  Readonly my $SANGER_OFFSET => 32;
  my @SAM_FIELDS    = qw(qname flag rname position mapq cigar rnext pnext tlen sequence quality optional);

  use Class::XSAccessor constructor => 'new', accessors => [ qw(qname flag rname position mapq cigar rnext pnext tlen sequence optional) ];#accessors => [grep { $_ ne 'quality'} @SAM_FIELDS, qw(raw)];

  sub end {
    my $self = shift;
    return $self->{end} if exists $self->{end};
    my $end = $self->position;
    while ($self->cigar =~ /([0-9]+)([MIDNSHPX=])/g) {
      my ($num, $operation) = ($1, $2);
      if ($operation =~ /[MDN=X]/) {
        $end += $num;
      }
    }
    $self->end($end);
    return $end;
  }

  sub print {
    my ($self) = shift;
    my $args = @_ == 1 && ref $_[0] ? $_[0] : {@_};
    my $fh = exists $args->{fh} ? $args->{fh} : $PRINT_DEFAULT_FH;
    print $fh $self->string . "\n";
  }

  sub string {
    my ($self) = @_;
    return join("\t", $self->qname, $self->flag, $self->rname, $self->position, $self->mapq, $self->cigar, $self->rnext, $self->pnext, $self->tlen, $self->sequence, $self->quality, $self->optional);
  }

  sub fastq {
    my ($self) = @_;
    return "@", $self->qname, "\n", $self->sequence, "\n+\n", $self->quality, "\n";
  }

  sub quality_array {
    my ($self, $new) = @_;
    if (defined $new) {
      $self->{quality_array} = $new;
      delete $self->{quality};
    }
    elsif (not exists $self->{quality_array}) {
      $self->{quality_array} = [map { $_ - $SANGER_OFFSET } unpack "c*", $self->quality];
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
      $self->{quality} = pack "c*", map { $_ + $SANGER_OFFSET } @{$self->{quality_array}};
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
}
1;
use namespace::autoclean;
