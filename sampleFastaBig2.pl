#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/21/2009
# Title:sampleFasta.pl
# Purpose:this script randomly samples a fasta or fastq file with or without replacement
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $replace;
my $sampleNum = 10;
my $paired;
my $prefix;
GetOptions('paired' => \$paired, 'prefix=s' => \$prefix, 'num|n=i' => \$sampleNum, 'replace|r' => \$replace, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# sampleFastaBig.pl
###############################################################################
use PerlIO;
use Term::ProgressBar;
sub procFasta($);
sub procRecord($);

my $firstChar;


my @fhs;
my @fileSizes;

my @records = ();
my @counts = ();
my %used = ();
my $totalSize = 0;
if(not $paired){
  print STDERR "Sampling $sampleNum sequences\n";
  for my $filename (@ARGV) {
    my $fileSize = -s $filename;
    $totalSize += $fileSize;
    push @fileSizes, $fileSize;
    my $fh;
    open $fh, "$filename";
    if (not $firstChar) {
      local $/ = \1;
      $firstChar = <$fh>;
    }
    push @fhs, $fh;
  }
  local $/ = $firstChar;
  my $count =0;

  my $bar = Term::ProgressBar->new({ count => $sampleNum, remove => 1, ETA => 'linear' });
  my $next_update = 0;
  while ($count < $sampleNum) {
    my $test = int(rand($totalSize));
    my ($fileItr,$filePos) = getFileItr($test);
    seek $fhs[$fileItr],$filePos,0;
    my $pre = readline($fhs[$fileItr]);
    my $record = readline($fhs[$fileItr]);
    chomp $record;
    my $good = 1;
    if (not $replace) {
      my ($header) = split /\n/,$record;
      if (exists $used{$header}) {
	$good = 0;
      }
    }
    if ($good) {
      print $firstChar,$record;
      $count++;
      $next_update = $bar->update($count) if $count >= $next_update;
    }
  }
  $bar->update($sampleNum) if $sampleNum >= $count;
} else { #paired
  my $file1 = shift;
  my $file2 = shift;
  my($pre,$suf) = removeExt($file1);
  unless($prefix){
    $prefix = "$pre.rand.$sampleNum";
  }
  open OUT1, ">:mmap","$prefix.1.$suf";
  open OUT2, ">:mmap","$prefix.2.$suf";
  my $size = -s $file1;
  open FH1, $file1;
  open FH2, $file2;
  local $/ = \1;
  my $firstChar = <FH1>;
  my $count = 0;
  my $bar = Term::ProgressBar->new({ count => $sampleNum, remove => 1, ETA => 'linear' });
  my $next_update = 0;
  $/ = $firstChar;
  while($count < $sampleNum) {
    my $test = int(rand($size));
    seek FH1, $test,0;
    seek FH2, $test,0;
    my $pre1 = readline(FH1);
    my $pre2 = readline(FH2);
    my $rec1 = readline(FH1);    chomp $rec1;
    my $rec2 = readline(FH2);    chomp $rec2;
    my $good = 1;
    if (not $replace) {
      my ($header1) = split /\n/,$rec1;
      my ($header2) = split /\n/,$rec2;
      if (exists $used{$header1} or exists $used{$header2}) {
	$good = 0;
      }
      $used{$header1}++;
      $used{$header2}++;
    }
    if ($good) {
      print OUT1 $firstChar,$rec1;
      print OUT2 $firstChar,$rec2;
      $count++;
      $next_update = $bar->update($count) if $count >= $next_update;
    }
  }
  $bar->update($sampleNum) if $sampleNum >= $count;
};

sub getFileItr{
  my($test) = shift;
  my $itr = 0;
  my $prevSize = 0;
  my $testSize = $fileSizes[0];
  while($test > $testSize){
    $prevSize = $testSize;
    $itr++;
    $testSize += $fileSizes[$itr];
  }
  return($itr,$test - $prevSize);
}

sub getRecords($){
  my $file = shift;
  my $recordPtr = shift;
  my $temp = $/;
  $/ = "\n";
  @{ $recordPtr } = map{($_) = split /:/}  `grep -boF \"$firstChar\" $file`;
  $/ = $temp;
}
sub removeExt{
  my $s = shift;
  if($s =~ m:(.+)\.([^/\.]*)$:){
    return($1,$2);
  }
  return($s,'');
}
###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

sampleFasta.pl - this script randomly samples a fasta or fastq file with or without replacement

=head1 SYNOPSIS

sampleFasta.pl [options] [file ...]

Options:
      -num,n
      -replace,r
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-num,n>

Set the number of records to get, default is 10

=item B<-replace,r>

Sets to sample with replacement, default is without replacement

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<sampleFasta.pl> this script randomly samples a fasta or fastq file with or without replacement

=cut

