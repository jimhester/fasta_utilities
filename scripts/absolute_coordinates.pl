#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/22/2011
# Title:absolute_coordinates.pl
# Purpose:this script takes a file with the chromosome and location and a file of chromosome sizes, and converts the coordinates to an absolute scale for plotting
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
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# absolute_coordinates.pl
###############################################################################

my $sizes = shift;

open SIZE, $sizes;

my %sizes = ();

while(<SIZE>){
  my($chromosome, $size) = split;
  $sizes{$chromosome}=$size;
}
close SIZE;
my %finalSizes = ();
my $sizeSoFar = 0;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use SortChr;
my @chrs = sort chrAsc keys %sizes;
print STDERR "@chrs\n";
for my $chr(@chrs){
  $finalSizes{$chr} = $sizeSoFar;
  $sizeSoFar += $sizes{$chr};
}
use FileBar;;

my $bar = FileBar->new();
while(<>){
  if(/(.*)(chr\d+)(\s+)(\d+)(.*)/s){
    my($before,$chromosome,$middle,$location,$after) = ($1,$2,$3,$4,$5);
    print $before, $finalSizes{$chromosome} + $location, $after;
  }
}
$bar->done();


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

absolute_coordinates.pl - this script takes a file with the chromosome and location and a file of chromosome sizes, and converts the coordinates to an absolute scale for plotting

=head1 SYNOPSIS

absolute_coordinates.pl [options] *.fa.fai [file ...]

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

B<absolute_coordinates.pl> this script takes a file with the chromosome and location and a file of chromosome sizes, and converts the coordinates to an absolute scale for plotting

=cut

