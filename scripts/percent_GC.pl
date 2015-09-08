#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/04/2011
# Title:percent_GC.pl
# Purpose:calculates percent GC for each fasta record in a file, as well as the total GC content
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
# percent_GC.pl
###############################################################################

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

my $totalGC=0;
my $totalBases=0;

my $fastx = ReadFastx->new();
while(my $seq = $fastx->next_seq){
  my $sequence = uc($seq->sequence);
  my $numGC = $sequence =~ tr/GC/GC/;
  $totalGC += $numGC;
  $totalBases += length($sequence);
  printf "%s\t%.2f%%\n", $seq->header, $numGC/length($sequence) * 100;
}
printf "total\t%d\t%d\t%.2f%%\n", $totalGC,$totalBases,$totalGC/$totalBases * 100;


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

percent_GC.pl - calculates percent GC for each fasta record in a file, as well as the total GC content

=head1 SYNOPSIS

percent_GC.pl [options] [file ...]

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

B<percent_GC.pl> calculates percent GC for each fasta record in a file, as well as the total GC content

=cut

