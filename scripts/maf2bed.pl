#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# Title:maf2bed.pl
# Created: 2012 Oct 17 01:40:32 PM - Jim Hester
# Modified: 2013 Mar 22 09:28:53 AM
# Purpose:converts a maf file to bed files
# By Jim Hester
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
# maf2bed.pl
###############################################################################
#
use parse_maf;
use cmp_c;

while(my $aln = next_aln()){
  for my $first_itr(0..$#{ $aln->{seqs} } -1){
    for my $second_itr($first_itr..$#{ $aln->{seqs} }){
      my($first,$second) = @{$aln->{seqs}}[$first_itr, $second_itr];
      if($second and $first->{name} ne $second->{name}){
        my $pid = cmp_c($first->{seq},$second->{seq}) / $first->{alnsize};
        print_alignment($first,$second,$aln->{score},$pid);
        print_alignment($second,$first,$aln->{score},$pid);
      }
    }
  }
}
sub print_alignment{
  my($first,$second,$score,$pid) = @_;
  my $second_name = join("_",$second->{name},$second->{start},$second->{end});
  printf "%s\t%d\t%d\t%s\t%d\n",$first->{name},$first->{start},$first->{end},
        $second_name,int($pid*1000);
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

maf2bed.pl - converts a maf file to bed files

=head1 SYNOPSIS

maf2bed.pl [options] [file ...]

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

B<maf2bed.pl> converts a maf file to bed files

=cut
