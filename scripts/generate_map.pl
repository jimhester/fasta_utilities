#!/usr/bin/perl
use warnings;
use Inline C;
use strict;
###############################################################################
# By Jim Hester
# Date:01/05/2012
# Title:generate_map.pl
# Purpose:remaps fasta sequences from the first file to fasta sequences from the second file, matches by hashing the sequence
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $remap;
my $identity=.99;
GetOptions('identity=f' => \$identity, 'remap' => \$remap, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# generate_map.pl
###############################################################################
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

my $map= ReadFastx->new(shift);

my %seqs;
while(my $seq = $map->next_seq){
  $seqs{uc $seq->sequence} = $seq->header;
  $seqs{revComp(uc $seq->sequence)} = $seq->header;
}

my $change = ReadFastx->new(shift);

while(my $seq = $change->next_seq){
  $seq->sequence(uc $seq->sequence);
  if(exists $seqs{$seq->sequence}){
    if($remap){
      $seq->header($seqs{$seq->sequence});
      $seq->print;
    } else {
      print $seqs{$seq->sequence},"\t",$seq->header,"\n";
    }
  } else {
    for my $check (keys %seqs){
      if(length $check == length $seq->sequence and 1 - cmp_c($seq->sequence, $check)/length($seq->sequence) > $identity){
        if($remap){
          $seq->header($seqs{$check});
          $seq->print;
        } else {
          print $seqs{$check},"\t",$seq->header,"\n";
        }
      }
    }
  }
}
sub revComp{
  my $sequence = shift;
  $sequence =~ tr/ACGTacgt/TGCAtgca/;
  return(reverse $sequence);
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

generate_map.pl - remaps fasta sequences from the first file to fasta sequences from the second file, matches by hashing the sequence

=head1 SYNOPSIS

generate_map.pl [options] [file ...]

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

B<generate_map.pl> remapps fasta sequences from the first file to fasta sequences from the second file, matches by hashing the sequence

=cut

__END__
__C__
int cmp_c(char *a, char *b)
{
    int total;
    total = 0;
    for (;*a && *b; a++, b++)
      if (*a != *b)
        total++;
    return(total);
}
