#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# Title:trans_fasta.pl
# Created: 2012 Oct 19 01:23:58 PM - Jim Hester
# Modified: 2012 Oct 19 01:27:58 PM - Jim Hester
# Purpose:translates a cDNA fasta file to protein
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
# trans_fasta.pl
###############################################################################
use Bio::SeqIO;

my $fastaI = Bio::SeqIO->new(-fh => \*ARGV,-format=>'fasta');
my $fastaO = Bio::SeqIO->new(-fh => \*STDOUT,-format=>'fasta');

while(my $seq = $fastaI->next_seq){
  $fastaO->write_seq($seq->translate);
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

trans_fasta.pl - translates a cDNA fasta file to protein

=head1 SYNOPSIS

trans_fasta.pl [options] [file ...]

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

B<trans_fasta.pl> translates a cDNA fasta file to protein

=cut

