#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:08/10/2012
# Title:pairs_sorted.pl
# Purpose:takes two files of reads sorted by header, and outputs two files containing those reads which have pairs
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $prefix;
my $extension;
GetOptions('extension=s' => \$extension, 'prefix=s' => \$prefix,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# pairs_sorted.pl
###############################################################################

my($file1,$file2) = @ARGV;
($prefix) = $file1 =~ /([^\/\.]+)\./ unless $prefix;
($extension) = $file1 =~ /\.([^\.]+)/ unless $extension;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

my($seq1,$seq2);

my $outFile1 = "$prefix-paired-1.$extension";
my $outFile2 = "$prefix-paired-2.$extension";
die "$outFile1 exists, will not overwrite\n" if -e $outFile1;
open OUT1, ">", $outFile1 or die "Could not open $outFile1";
open OUT2, ">", $outFile2 or die "Could not open $outFile2";

my $fastx1 = ReadFastx->new($file1);
my $fastx2 = ReadFastx->new($file2);
while($seq1 = $fastx1->next_seq){
  while((not $seq2 and $seq2 = $fastx2->next_seq) or $seq2->header lt $seq1->header and $seq2 = $fastx2->next_seq){}
  if($seq1 and $seq2 and $seq1->header eq $seq2->header){
    $seq1->print(fh => \*OUT1);
    $seq2->print(fh => \*OUT2);
  }
}
exit;
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

pairs_sorted.pl - takes two files of reads sorted by header, and outputs two files containing those reads which have pairs

=head1 SYNOPSIS

pairs_sorted.pl [options] [file ...]

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<pairs_sorted.pl> takes two files of reads sorted by header, and outputs two files containing those reads which have pairs

=cut

