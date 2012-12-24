package SortChr;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT);

 # set the version for version checking
  $VERSION = 1.00;

  @ISA = qw(Exporter);
  @EXPORT  = qw(&sort_chr);
}

sub sort_chr{
  my($array,$type) = @_;
  $type = 'asc' unless $type;
  if ($type eq 'asc') {
    return(
      map { $_->[0] }
      sort { $a->[1] <=> $b->[1] || $a->[0] cmp $b->[0]}
      map { [$_, chr_num($_)] }
      @{ $array });
  }
  else{
    return(
      map { $_->[0] }
      sort { $a->[1] <=> $b->[1] || $a->[0] cmp $b->[0]}
      map { [$_, chr_num($_)] }
      @{ $array });
  }
}
sub split_chr(){
  if($_[0] =~ /(\d+)/){
    return $1;
  }
  return 0;
}
1;
