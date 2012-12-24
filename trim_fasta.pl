#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/15/2009
# Title:trim_fasta.pl
# Purpose:
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man      = 0;
my $help     = 0;
my $amount   = 36;
my $startPos = 0;
my $random;

GetOptions('num|trim|amount|t|a|n=i' => \$amount,
           'start=i'                 => \$startPos,
           'random|r'                => \$random,
           'help|?'                  => \$help,
           man                       => \$man)
  or pod2usage(2);

pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/; $_ } @ARGV;
###############################################################################
# trim_fasta.pl
###############################################################################

use ReadFastx;

my $file = ReadFastx->new();

while (my $seq = $file->next_seq) {
  if ($random) {
    $startPos = int(rand(length($seq->sequence) - $amount));
  }
  $seq->sequence(substr($seq->sequence, $startPos, $amount));
  if ($seq->can("quality")) {
    $seq->quality(substr($seq->quality, $startPos, $amount));
  }
  $seq->print;
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

trim_fasta.pl - 

=head1 SYNOPSIS

trim_fasta.pl [options] [file ...]

Options:
      -t,-n,-a,-trim,-num,-amount
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-t,-n,-a,-trim,-num,-amount>

Set the amount to trim

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<trim_fasta.pl> 

=cut

