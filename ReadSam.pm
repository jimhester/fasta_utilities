use warnings;
use strict;
{

  package ReadSam;
  use Class::XSAccessor getters => [qw(fh files header)], accessors => [qw(is_phred64)];
  use Carp;
  use FileBar;
  use Readonly;

  #hack to use autodie with overridden builtins
  sub close {
    use autodie qw(close);
    my ($self) = @_;
    delete $self->{prev};
    CORE::close $self->fh;
  }

  use autodie;

  Readonly my $COMMENT_CODE => 'CO';
  Readonly my @SAM_FIELDS => qw(qname flag rname position mapq cigar rnext pnext tlen sequence quality optional);
  our $VERSION = '0.20';

  sub new {
    my $class = shift;
    my $self;
    if (@_ == 1 && !ref $_[0]) {
      $self->{files} = [$_[0]];
    }
    else {
      $self = {@_};
    }
    $self = bless $self, $class;
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
      my $line  = readline $self->fh;
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
    my %ref;
    for my $value (split /[\t\n]/, $line) {
      if ($itr < @SAM_FIELDS-1) {
        $ref{$SAM_FIELDS[$itr]} = $value;
      }
      else {
        my ($tag, $val) = $value =~ m{([A-Z0-9]+):(.*)};
        $ref{optional}{$tag} = $val;
      }
      $itr++;
    }
    $ref{raw} = $line;
    return ReadSam::SamAlignment->new(%ref, is_phred64 => $self->is_phred64);
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
    open my ($fh), $file;
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

  use namespace::autoclean;
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
        if ($code eq $COMMENT_CODE) {
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
    return $lines;
  }
  use namespace::autoclean;
}

{

  package ReadSam::SamAlignment;
  use Readonly;

  Readonly my $PRINT_DEFAULT_FH => \*STDOUT;
  Readonly my $SANGER_OFFSET    => 32;
  my @SAM_FIELDS = qw(qname flag rname position mapq cigar rnext pnext tlen sequence quality optional);

  use Class::XSAccessor constructor => 'new', accessors => [qw(qname flag rname position mapq cigar rnext pnext tlen sequence optional raw)];

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
    $self->{end} = $end;
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
    my $optional = join("\t", map { $_ . ':' . $self->optional->{$_} } keys %{$self->optional});
    return join("\t", $self->qname, $self->flag, $self->rname, $self->position, $self->mapq, $self->cigar, $self->rnext, $self->pnext, $self->tlen, $self->sequence, $self->quality, $optional);
  }

  sub fastq {
    my ($self)   = @_;
    my $sequence = $self->sequence;
    my $quality  = $self->quality;
    if ($self->flag & 0x10) {
      $sequence = reverse_complement($sequence);
      $quality  = reverse($quality);
    }
    my $qname = $self->qname;
    if ($self->flag & 0x40) {
      $qname .= "/1";
    }
    elsif ($self->flag & 0x80) {
      $qname .= "/2";
    }
    return "@", $qname, "\n", $sequence, "\n+\n", $quality, "\n";
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
  use namespace::autoclean;
}
1;
