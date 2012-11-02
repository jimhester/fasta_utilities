#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/21/2009
# Title:sampleBam.pl
# Purpose: samples a bam file for the given number of pairs
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
my $outfile;
GetOptions('out=s' => \$outfile,'paired' => \$paired, 'prefix=s' => \$prefix, 'num|n=i' => 
\$sampleNum, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# sampleBamBig.pl
###############################################################################
# this uses reservoir sampling 
use JimBar;
use Bio::DB::Sam;

my $num = 1;

if($paired){
  foreach my $file (@ARGV) {
    ($prefix) = removeExt($file) unless $prefix;
    my $out = Bio::DB::Bam->open("$prefix.rand.$sampleNum.bam", "w");
    my $bam = Bio::DB::Bam->open($file);
    $out->header_write($bam->header);
    my $pos = $bam->tell();
    my $firstAln = $bam->read1();
    my $pos2 = $bam->tell();
    my @reservoir;
    while(my $secondAln = $bam->read1()){
      if($firstAln->qname eq $secondAln->qname){ #only do this if both are paired
        if($num <= $sampleNum){
          push @reservoir,$pos;
        } else {
          if(rand() < $sampleNum/$num ){
            $reservoir[rand($sampleNum)]=$pos;
          }
        }
      }
      while(defined $secondAln and $firstAln->qname eq $secondAln->qname){
        $secondAln = $bam->read1();
      }
      $firstAln = $secondAln;
      $num++;
      $pos = $pos2;
      $pos2 = $bam->tell();
    }
##    use Data::Dumper;
#    print STDERR Dumper(@reservoir);
#    for my $pos(@reservoir){
#      $bam->seek($pos,0);
#      my $firstAln = $bam->read1();
#      print Dumper($firstAln);
#      $out->write1($firstAln);
#      my $secondAln = $bam->read1();
#      while(defined $secondAln and $secondAln->qname eq $firstAln->qname){
#        $out->write1($secondAln);
#        $secondAln = $out->read1();
#      }
#    }
  }
}
else {
  my $file = shift;
  my $bam = Bio::DB::Bam->open($file);
  my $out = Bio::DB::Bam->open($outfile, "w");
  $out->header_write($bam->header);
  my @reservoir;
  $#reservoir = $sampleNum-1;
  while(my $aln = $bam->read1()){
    if($num <= $sampleNum){
      $reservoir[$num-1]=$aln;
    } elsif(rand() < $sampleNum/$num){
      $reservoir[rand($sampleNum)]=$aln;
    }
    $num++;
    print STDERR "\r$num" if $num % 100000 == 0;
  }
  print STDERR scalar @reservoir;
  for my $aln(@reservoir){
    $out->write1($aln);
  }
  #$out->close;
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

sampleBam.pl - this script randomly samples a fasta or fastq file with or without replacement

=head1 SYNOPSIS

sampleBam.pl [options] [file ...]

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

B<sampleBam.pl> this script randomly samples a fasta or fastq file with or without replacement

=cut


