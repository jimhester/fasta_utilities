#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 May 07 03:00:07 PM
# Last Modified: 2013 May 07 03:07:53 PM
# Title:ascii2csv.pl
# Purpose:Converts whitespace ascii to csv
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my %args = ();
GetOptions(\%args, 'help|?', 'man') or pod2usage(2);
pod2usage(2) if exists $args{help};
pod2usage(-verbose => 2) if exists $args{man};
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# ascii2csv.pl
###############################################################################

use Text::CSV;

my $csv = Text::CSV->new();

while(<>){
  my @lines = split;
  $csv->print(\*STDOUT, \@lines);
  print "\n";
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

ascii2csv.pl - Converts whitespace ascii to csv

=head1 VERSION

0.0.1

=head1 USAGE

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<ascii2csv.pl> Converts whitespace ascii to csv

=cut

