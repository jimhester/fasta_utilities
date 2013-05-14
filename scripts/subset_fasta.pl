#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2012 Dec 06 01:28:48 PM
# Last Modified: 2013 Apr 18 12:57:56 PM
# Title:subset_fasta.pl
# Purpose:subsets a fasta file
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $step;
my $size;
my $percentage;
my $only_full;
my $n_max;
GetOptions('step=i'       => \$step,
           'size=i'       => \$size,
           'percentage=f' => \$percentage,
           'only_full'    => \$only_full,
           'n_max=i'      => \$n_max,
           'help|?'       => \$help,
           man            => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));

$size = 100   unless $size;
$step = $size unless $step;
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/; $_ } @ARGV;
###############################################################################
# subset_fasta.pl
###############################################################################

use ReadFastx;
my $fastx = ReadFastx->new();
while (my $seq = $fastx->next_seq) {
  if ($percentage) {
    $size = int(length($seq->sequence) / $percentage);
    $step = $size;                                       #TODO variable/percentage steps
  }
  my $pos    = 0;
  my $length = length($seq->sequence);
  my $stop = $only_full ? $length - $size : $length;
  while ($pos < $stop) {
    my $str = substr($seq->sequence, $pos, $size);
    unless($n_max and $str =~ tr/N/N/ > $n_max){
      my $header = $seq->header . ':' . $pos . '-' . ($pos + $size);
      print ">", $header, "\n", $str, "\n";
    }
    $pos += $step;
  }
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

subset_fasta.pl - subsets a fasta file

=head1 SYNOPSIS

subset_fasta.pl [options] [file ...]

Options:
      -step
      -size
      -percentage
      -only_full
      -n_max
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-step> <size>

Set the step size for the subset

=item B<-size> <100>

Set the size of the subset

=item B<-percentage> <float>

Set the percentage of each record to subset, overrides size if set

=item B<-only_full>

Only print subsets which are the correct size, no smaller subsets reported

=item B<-n_max> <Inf>

Only print subsets which have this number of N's or fewer

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<subset_fasta.pl> subsets a fasta file

=cut

