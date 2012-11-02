#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/19/2012
# Title:getRegion.pl
# Purpose:this script masks all but specific region from a fasta file
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
GetOptions('help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# getRegion.pl
###############################################################################

use readFastx;

my $region = shift;

my($chr, $region_start,$region_end) = split /[:-]/,$region;

my $file = readFastx->new();

while(my $seq = $file->next_seq){
  if($seq->header eq "$chr"){
    my $start = $region_start - 1; #UCSC regions are 1-based,half open
    my $end = $region_end;
    my $finalSeq = ("N") x $start;
    $finalSeq .= substr($seq->sequence,$start,$end-$start);
    $finalSeq .= ("N") x (length($seq->sequence)-$end);
    $seq->sequence = $finalSeq;
    $seq->print(undef,80);
  }
}


###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

getRegion.pl - this script masks all but specific region from a fasta file

=head1 SYNOPSIS

getRegion.pl [options] [file ...]

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

B<getRegion.pl> this script masks all but specific region from a fasta file

=cut

