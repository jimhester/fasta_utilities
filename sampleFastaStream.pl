#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/21/2009
# Title:sampleFasta.pl
# Purpose:this script randomly samples a fasta or fastq stream without 
# replacement
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
GetOptions('paired' => \$paired, 'prefix=s' => \$prefix, 'num|n=i' => 
\$sampleNum, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# sampleFastaBig.pl
###############################################################################
# this uses reservoir sampling 
#
use JimBar;
use readFastx;

my $num = 1;

if($paired){
  my @files = @ARGV;
  #hack to get JimBar to work properly, only pass in odd files
  #my $ind = 1;
  #grep{$ind++ % 2} @ARGV;
  #my $bar = JimBar->new();
  while(my $file1 = shift @files and
     my $file2 = shift @files){
    my $reads1 = readFastx->new($file1);
    my $reads2 = readFastx->new($file2);
    my($pre,$suf) = removeExt($file1);
    unless($prefix){
      $prefix = "$pre.rand.$sampleNum";
    }
    my @reservoir1;
    my @reservoir2;
    while(defined (my $seq1 = $reads1->next_seq) and
      defined (my $seq2 = $reads2->next_seq)){
      if($num <= $sampleNum){
        push @reservoir1,$seq1;
        push @reservoir2,$seq2;
      } else {
        if(rand() < $sampleNum/$num ){
          $reservoir1[rand($sampleNum)]=$seq1;
          $reservoir2[rand($sampleNum)]=$seq2;
        }
      }
      $num++;
    }
    open OUT1, ">$prefix.1.$suf";
    for my $seq(@reservoir1){
      $seq->print(\*OUT1);
    }
    open OUT2, ">$prefix.2.$suf";
    for my $seq(@reservoir2){
      $seq->print(\*OUT2);
    }
    close OUT1; close OUT2;
  }
} else {

  my $file = readFastx->new();
  my $bar = JimBar->new();

  my @reservoir;

  my $num = 1;
  while(my $seq = $file->next_seq){
    if($num <= $sampleNum){
      push @reservoir,$seq;
    } else {
      if(rand() < $sampleNum/$num ){
        $reservoir[rand(@reservoir)]=$seq;
      }
    }
    $num++;
  }
  for my $seq(@reservoir){
    $seq->print;
  }
}
sub removeExt{
  my $s = shift;
  if($s =~ m:(.+)\.([^/\.]*)\b:){
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

