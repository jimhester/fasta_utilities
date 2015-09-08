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
my @mott;
my $random;

GetOptions('num|trim|amount|t|a|n=i' => \$amount,
           'start=i'                 => \$startPos,
           'random|r'                => \$random,
           'bwa:i'             => \$bwa,
           'mott:f{,2}'            => \@mott,
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

my @probs;
my @mott_defaults = (0.05, 30);
if(@mott){
  @mott = mott_defaults(\@mott);
  use Data::Dumper;
  warn Dumper(@mott);
  #phred scores from 33 to 128
  @probs = map { 10**(-$_/10) } 0..98;
}



#$bwa = 20 if $bwa == 0;

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;

my $file = ReadFastx->new();

while (my $seq = $file->next_seq) {
  if($bwa){
    $startPos = 0;
    $amount = bwa_cut($seq);
  }
  elsif(@mott){
    my $end;
    ($startPos, $end) = mott($seq, @mott);
    $amount = $end - $startPos - 1;
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
  return $good_amount;
}

sub mott{
  my($sequence, $cutoff, $min_length) = @_;
  my $qualities = $sequence->quality_array();

  my($begin, $temp, $end, $sum, $max) = (0) x 5;

  if(@{ $qualities } > $min_length){
    for my $itr(0..$#{ $qualities }){
      $sum += $cutoff - $probs[$qualities->[$itr]];
      if($sum > $max){
        $max = $sum;
        $begin = $temp;
        $end = $itr + 1;
      }
      if($sum < 0){
        $sum = 0;
        $temp = $itr + 1;
      }
    }
    if($end - $begin < $min_length){
      my($is, $imax, $itr);
      for $itr(0..($min_length-1)){
        $is += $qualities->[$itr];
      }
      $imax = $is;
      $begin = 0;
      for $itr($itr..$#{ $qualities} ){
        $is += $qualities->[$itr] - $qualities->[$itr - $min_length];
        if($imax < $is){
          $imax = $is;
          $begin = $itr - $min_length + 1;
        }
      }
      $end = $begin + $min_length;
    }
  }
  else {
    $begin = 0;
    $end = @{ $qualities };
  }
  return($begin, $end);
}
#sets mott defaults if they are not given
sub mott_defaults {
  my($val_ref) = @_;

  #return if the mott argument is not used
  return undef unless @{ $val_ref };

  return map { $val_ref->[$_] ? $val_ref->[$_] : $mott_defaults[$_] } 0..1;
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
      -bwa
      -mott
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-bwa>

Trim based on qualities using the 1 sided algorithm used in bwa.

=item B<-mott>

Trim based on qualities using the 2 sided modified Richard Mott's algorithm used in Phred.

=item B<-t,-n,-a,-trim,-num,-amount>

Trim a set number of bases.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<trim_fasta.pl> 

=cut

