#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:05/14/2012
# Title:/home/hesterj/fu/formatAfterSort.pl
# Purpose:formats a fasta file with the arguments given after processing by gnu sort
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my %options;
GetOptions(\%options, 'chr|c','sequence|s', 'header|h' ,'length|l' ,'reverse|v' ,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# /home/hesterj/fu/formatAfterSort.pl
###############################################################################

local $/ = "\0";

while(<>){
  if(exists $options{sequence}){
    my $headerStart = index($_,"@",1);
    my $qualityStart = index($_,"\n",$headerStart);
    print substr($_,$headerStart,$qualityStart-$headerStart+1)
    . substr($_,1,$headerStart-1).substr($_,$qualityStart+1,-1);
  } elsif(exists $options{length} or exists $options{chr}){
    my $headerStart = index($_,"\n",1);
    print substr($_,$headerStart+1,-1);
  } elsif(exists $options{header}){
    print substr($_,0,-1);
  }
}
#use readFastx;
#
#my $fasta = readFastx->new();
#
#while(my $seq = $fasta->next_seq){
#  $seq->header =~ tr/@\0//d;
#  $seq->print;
#}



###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

/home/hesterj/fu/formatAfterSort.pl - formats a fasta file with the arguments given after processing by gnu sort

=head1 SYNOPSIS

/home/hesterj/fu/formatAfterSort.pl [options] [file ...]

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

B</home/hesterj/fu/formatAfterSort.pl> formats a fasta file with the arguments given after processing by gnu sort

=cut

