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
my $bwa;
my $random;

GetOptions('num|trim|amount|t|a|n=i' => \$amount,
           'start=i'                 => \$startPos,
           'random|r'                => \$random,
           'bwa-quality:i'             => \$bwa,
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

$bwa = 20 if $bwa == 0;

use ReadFastx;

my $file = ReadFastx->new();

while (my $seq = $file->next_seq) {
  if($bwa){
    $startPos = 0;
    $amount = bwa_cut($seq);
  }
  elsif ($random) {
    $startPos = int(rand(length($seq->sequence) - $amount));
  }
  $seq = trim($seq, $startPos, $startPos + $amount);
  $seq->print;
}

sub trim{
  my($sequence, $start, $end) = @_;

  $sequence->sequence(substr($sequence->sequence, $start, $end-$start + 1));
  if ($sequence->can("quality")) {
    $sequence->quality(substr($sequence->quality, $start, $end-$start + 1));
  }
  return $sequence;
}

#taken from https://github.com/lh3/bwa/blob/master/bwaseqio.c
sub bwa_cut{
  my($sequence) = @_;

  my $qualities = $sequence->quality_array();

  my $good_amount = @{ $qualities };
  my $sum = 0;
  my $max = 0;

  my $itr = $#{ $qualities };
  while($itr >= 0){
    $sum += $bwa - $qualities->[$itr];
    if($sum > $max){
      $max = $sum;
      $good_amount = $itr;
    }
    last if $sum < 0;
    $itr--;
  }
  warn $good_amount;
  return $good_amount;
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

