package readFastx;
use JimBar;
use warnings;
use strict;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->{name} = shift;
  $self->__initialize__();
  return $self;
}
sub __initialize__{
  my $self = shift;
  if($self->{name}){
    unless (ref $self->{name} =~ /GLOB/) {
      $self->{filename} = $self->{name};
      open $self->{fh}, $self->{filename} or die "$! Could not open ".$self->{filename}."\n";
      $self->{useBar} = 1 unless($self->{filename} =~ /\|/);
      $self->{bar} = JimBar->new($self->{fh},$self->{filename}) if $self->{useBar};
    } else {
      $self->{fh} = $self->{name};
    }
  } else {
    $self->{bar} = JimBar->new();
    $self->{fh} = *ARGV;
  }
  
  local $/ = \1;
  my $first = readline $self->{fh};
  if($first eq ">"){
    $self->{reader} = readFastx::Fasta->new($self->{fh});
  } elsif($first eq "@"){
    $self->{reader} = readFastx::Fastq->new($self->{fh});
  } else {
    die $ARGV . " is not a fasta or fastq file, first character is not > or @\n" if $first ne ">" or $first ne "@";
  }
  $self->{file} = $ARGV;
}

sub seek{
  my($self,$amount,$whence) = @_;
  seek $self->{fh},$amount,$whence;
}
sub next_seq{
  my $self = shift;
  $self->{count}++;
  if($ARGV ne $self->{file}){
    $self->{reader}->next_seq;
  }
  $self->{file} = $ARGV;
  my $seq = $self->{reader}->next_seq;
  if(not $seq){
    $self->{bar}->done if exists $self->{useBar};
    close $self->{fh} if $self->{filename};
  }
  #print STDERR "\r".$self->{count} if $self->{count} % 10000 == 0 and not 
  #exists $self->{useBar};
  return($seq);
}
sub find_next{
  my($self) = @_;
  return $self->{reader}->find_next;
}

sub message{
  my ($self,$message) = @_;
  $self->{bar}->message($message);
}
sub file{
  my ($self) = @_;
  return $self->{file};
}
package readFastx::Fasta;

sub new{
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->{fh} = shift;
  $self->__init__;
  return $self;
}
sub __init__{
  my $self = shift;
  local $/ = ">";
  if(defined ($_ = readline $self->{fh})){
    chomp;
    my $newline = index($_,"\n");
    my $seq = readFastx::Fasta::Seq->new();
    $seq->header = substr($_, 0,$newline);
    $seq->sequence = substr($_,$newline+1);
    $seq->sequence =~ tr/\n//d;
    $self->{prev} = $seq;
  }
}
sub next_seq{
  my $self = shift;
  my $return = $self->{prev};
  if($return and $return->header ne ">"){
    local $/ = ">";
    if(defined ($_ = readline $self->{fh})){
      chomp;
      my $newline = index($_,"\n");
      my $seq = readFastx::Fasta::Seq->new();
      $seq->header = substr($_, 0,$newline);
      $seq->sequence = substr($_,$newline+1);
      $seq->sequence =~ tr/\n//d;
      $self->{prev} = $seq;
    } else {
      $self->{prev} = undef;
    }
  }
  return($return);
}
sub find_next{
  my($self) = @_;
  local $/ = ">";
  readline $self->{fh};
  if(defined ($_ = readline $self->{fh})){
    chomp;
    my $newline = index($_,"\n");
    my $seq = readFastx::Fasta::Seq->new();
    $seq->header = substr($_, 0,$newline);
    $seq->sequence = substr($_,$newline+1);
    $seq->sequence =~ tr/\n//d;
    $self->{prev} = $seq;
    return 1;
  } else {
    $self->{prev} = undef;
    return undef;
  }
}

package readFastx::Fasta::Seq;

sub new{
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}
sub header : lvalue{
  my $self = shift;
  $self->{header};
} 
sub sequence : lvalue{
  my $self = shift;
  $self->{sequence};
}
sub quality {
  return(undef);
}
sub print{
  my $self = shift;
  my $fh = shift || \*STDOUT;
  my $width = shift || undef;
  my $out;
  if($width){
    my $cur = 0;
    while($cur < length($self->{sequence})){
      $out .= substr($self->{sequence},$cur,$width) . "\n";
      $cur += $width;
    }
  } else {
    $out = $self->{sequence} . "\n";
  }
  print $fh ">".$self->{header}."\n$out";
}

package readFastx::Fastq;

sub new{
  my $class = shift;
  my $self = {};
  $self->{fh} = shift;
  bless $self, $class;
  $self->__init__;
  return $self;
}
sub __init__{
  my $self = shift;
  local $/ = "\n";
  if(defined (my $header = readline $self->{fh}) and
    defined (my $sequence = readline $self->{fh}) and
    defined (my $h2 = readline $self->{fh}) and
    defined (my $quality = readline $self->{fh})) {
    my $seq = readFastx::Fastq::Seq->new();
    $seq->header = substr($header, 0,-1);
    $sequence =~ tr/\n//d;
    $seq->sequence = $sequence;
    $quality =~ tr/\n//d;
    $seq->quality = $quality;
    $self->{prev} = $seq;
  } else {
    $self->{prev} = undef;
  }
}
sub next_seq{
  my $self = shift;
  my $return = $self->{prev};
  if($return){
    if(defined (my $header = readline $self->{fh}) and
      defined (my $sequence = readline $self->{fh}) and
      defined (my $h2 = readline $self->{fh}) and
      defined (my $quality = readline $self->{fh})) {
      my $seq = readFastx::Fastq::Seq->new();
      $seq->header = substr($header, 1,-1);
      chomp $sequence;
      chomp $quality;
      $seq->sequence = $sequence;
      $seq->quality = $quality;
      $self->{prev}=$seq;
    } else {
      close $self->{fh};
      $self->{prev}=undef;
    }
  }
  return($return);
}
package readFastx::Fastq::Seq;

sub new{
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}
sub header : lvalue{
  my $self = shift;
  $self->{header};
} 
sub sequence : lvalue{
  my $self = shift;
  $self->{sequence};
}
sub quality : lvalue{
  my $self = shift;
  $self->{quality};
}
sub print{
  my $self = shift;
  my $fh = shift || \*STDOUT;
  print $fh "@" . $self->{header}."\n" . $self->{sequence} . "\n+" . $self->{header} . "\n" . $self->{quality} . "\n";
}
1;
