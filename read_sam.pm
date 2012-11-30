package read_sam;
use Moose;

local @ARGV;

has fh => ( is => 'ro', isa => 'GlobRef');
has files => ( is => 'ro', default => sub { \@ARGV }, isa => 'ArrayRef[Str]');
has alignments_only => (is => 'ro', default => 0, isa => 'Bool');

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  if ( @_ == 1 && ! ref $_[0] ) {
    if (ref $_[0] eq "GLOB") { #filehandle
      return $class->$orig(fh => $_[0]);
    } elsif(ref $_[0] eq "ARRAY"){ #array of files
      return $class->$orig(files => $_[0]);
    } else { #single file
      return $class->$orig(files => [ $_[0] ]);
    }
  }
  else {
      return $class->$orig(@_);
  }
};
sub BUILD {
  my $self = shift;
  unless ( $self->fh ) {
    @{ $self->{files} } = map { s/(.*\.bam)\s*$/samtools view -h $1|/;$_ } @{ $self->files }; #pipe bam files through samtools
    @ARGV = @{ $self->files };
    $self->{fh} = \*ARGV;
  }
}
sub readline {
  my $self = shift;
  my $line = readline $self->fh;
  my $headers;
  while($line =~ /^@/){
    $headers .= $line;
    $line = readline $self->fh;
  }
  return sam_header->new($headers) if($headers and not $self->alignments_only);
  return $self->parse_line($line);
}
sub parse_line{
  my $self = shift;
  my $line = shift;
  return unless $line;
  my @fields = qw( qname flag rname position mapq cigar rnext pnext tlen sequence);
  my $itr = 0;
  my %ref;
  my @options;
  for my $value(split /[\t\n]/, $line){
    if($itr <= $#fields){
      $ref{$fields[$itr]}=$value;
    } elsif($itr == $#fields+1){
      $ref{quality}=[ map { $_ - 64 } unpack "c*",$value ];
    } else {
      push @options, $value;
    }
    $itr++;
  }
  $ref{optional}=\@options;
  $ref{raw}=$line;
  return sam_alignment->new(\%ref);
}
package sam_header;
use Moose;

has raw => ( is => 'ro', isa => 'Str');
has tags => ( is => 'rw', isa => 'HashRef[ArrayRef[HashRef[Str]]]');

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  if ( @_ == 1 && ! ref $_[0] ) {
    return $class->$orig(raw => $_[0]);
  } else{
    return $class->orig(@_);
  }
};
sub BUILD {
  my $self = shift;
  for my $line(split /[\r\n]+/, $self->raw){
    my($code,@tags) = split /\t/, $line;
    $code =~ s/^@//;
    if($code eq "CO"){
      push @{ $self->{tags}{CO} }, {Comment => join("\t",@tags)};
    } else{
      my %tags;
      for my $tuple(@tags){
        my($tag,$value) = split /:/,$tuple;
        $tags{$tag}=$value;
      }
      push @{ $self->{tags}{$code} }, \%tags;
    }
  }
}
sub lines{
  my $self = shift;
  my $lines;
  for my $code( keys %{ $self->{tags} }){
    for my $item( @{ $self->{tags}{$code} }){
      my $line = $code;
      if($code eq "CO"){
        $line .= "\t" . $self->{tags}{$code}{$item}{Comment};
      } else{
        for my $tag (keys %{ $item }){
          $line .= "\t" . $tag . ":" . $item->{$tag};
        }
      }
      $lines .= "$line\n";
    }
  }
}
package sam_alignment;
use Moose;

has qname => ( is => 'rw' , isa => 'Str');
has flag => ( is => 'rw', isa => 'Str');
has rname => ( is => 'rw', isa => 'Str');
has position => ( is => 'rw', isa => 'Int');
has mapq => ( is => 'rw', isa => 'Int');
has cigar => ( is => 'rw', isa => 'Str');
has rnext => ( is => 'rw', isa => 'Str');
has pnext => ( is => 'rw', isa => 'Int');
has tlen => ( is => 'rw', isa => 'Int');
has sequence => ( is => 'rw', isa => 'Str');
has quality => ( is => 'rw', isa => 'ArrayRef[Int]');
has optional => ( is => 'rw', isa => 'ArrayRef[Str]');
has raw => (is => 'ro', isa => 'Str');

sub end{
  my ($self,$cigar) = @_;
  return $self->{end} if exists $self->{end};
  my $end = $self->position;
  while($cigar =~ /([[0-9]+)([MIDNSHPX=])/g){
    my($num,$operation)=($1,$2);
    if($operation =~ /[MDN=X]/){
      $end+=$num;
    }
  }
  $self->{end} = $end;
  return $end;
}
sub print{
  my($self,$fh) = @_;
  $fh = \*STDOUT unless $fh;
  print $fh $self->string."\n";
}
sub string{
  my($self) = @_;
  return join("\t", $self->qname, $self->flag, $self->rname, $self->position, 
    $self->mapq, $self->cigar, $self->rnext, $self->pnext, $self->tlen, 
    $self->sequence, pack("c*", map { $_ + 64 } @{ $self->quality }), 
    @{ $self->optional });
}
__PACKAGE__->meta->make_immutable;

1;
