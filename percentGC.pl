#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/04/2011
# Title:percentGC.pl
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
# percentGC.pl
###############################################################################

local $/ = \1;

my $firstChar = <>;

$/ = $firstChar;

my $totalGC;
my $totalBases;
while(<>){
  chomp;
  my $headerEnd = index($_,"\n");
  my $header = substr($_,0,$headerEnd);
  my $sequenceEnd = index($_,"+",$headerEnd);
  my $sequence = uc(substr($_,$headerEnd,$sequenceEnd));
  $sequence =~ tr/\nN//d;
  my $numGC = $sequence =~ tr/GC/GC/;
  printf "$header\t%.2f%%\n", $numGC/length($sequence) * 100;
  $totalGC += $numGC;
  $totalBases += length($sequence);
}

printf "total\t%d\t%d\t%.2f%%\n", $totalGC,$totalBases,$totalGC/$totalBases * 100;


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

percentGC.pl - calculates percent GC for each fasta record in a file, as well as the total GC content

=head1 SYNOPSIS

percentGC.pl [options] [file ...]

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

B<percentGC.pl> calculates percent GC for each fasta record in a file, as well as the total GC content

=cut

