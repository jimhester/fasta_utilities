use JimBar;
package read_fastx;
sub new(){
  my $class = shift;
  my $self = {};
  ($self->{name}) = @_;
  if($self->{name}){
    if (not ref $self->{name} =~ /GLOB/) {
      $self->{filename} = $self->{name};
      open $self->{fh}, $self->{filename} or die "$! Could not open ".$self->{filename}."\n";
      $self->{useBar} = 1 unless($self->{filename} =~ /\|/);
      $self->{bar} = JimBar->new($self->{fh},$self->{filename}) if $self->{useBar};
    } else { #name is a file handle, just assign it
      $self->{fh} = $self->{name};
    }
  } else {
    $self->{bar} = JimBar->new();
    $self->{fh} = *ARGV;
  }
  local $/=\1;
  my $first = readline $self->{fh};
  if($first eq ">"){
    $self->{reader} = read_fasta->new($self->{fh});
  } elsif($first eq "@"){
    $self->{reader} = read_fastq->new($self->{fh});
  } else {
    die $ARGV . " is not a fasta or fastq file, first character is not > or @\n" if $first ne ">" or $first ne "@";
  }
  bless $self, $class;
  return $self;
}
sub next_seq{
  my $self = shift;
  return($self->{reader}->next_seq);
}
package read_fasta;
sub new(){
  my $class = shift;
  my $self = {};
  ($self->{fh}) = @_;
  die "Must define a file handle\n" unless $self->{fh};
  bless $self, $class;
  return $self;
}
sub next_seq{
  my $self = shift;
  local $/=">";
  if($_ = readline $self->{fh}){
    my $newline = index($_,"\n");
    if($newline > 1){
      my $seq = fasta->new();
      $seq->header = substr($_, 0,$newline);
      $seq->sequence = substr($_,$newline+1,-1);
      $seq->sequence =~ tr/\n//d;
      return $seq;
    } else {
      #just read first line of a new file so return next record
      return($self->next_seq); 
    }
  } else {
    return undef;
  }
}
package read_fastq;
sub new(){
  my $class = shift;
  my $self = {};
  ($self->{fh}) = @_;
  die "Must define a file handle\n" unless $self->{fh};
  bless $self, $class;
  return $self;
}
sub next_seq{
  my $self = shift;
  if(defined ($header = readline $self->{fh}) and
     defined ($sequence = readline $self->{fh}) and
     defined ($h2 = readline $self->{fh}) and 
     defined ($quality = readline $self->{fh})){
    $header =~ s/^@//; #remove @ if it exists
    chomp $header; chomp $sequence; chomp $quality;
    $seq = fastq->new($header,$sequence,$quality);
    return $seq;
  } else {
    return undef;
  }
}
package fasta;
sub new{
  my $class = shift;
  my $self = {};
  ($self->{header},$self->{sequence}) = @_;
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
package fastq;
sub new{
  my $class = shift;
  my $self = {};
  ($self->{header},$self->{sequence},$self->{quality}) = @_;
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
