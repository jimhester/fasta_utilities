#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:05/14/2012
# Title:/home/hesterj/fu/formatForSort.pl
# Purpose:formats a fasta file with the arguments given for processing by gnu sort
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
# /home/hesterj/fu/formatForSort.pl
###############################################################################

#my %ARGS = @ARGV;

use readFastx;

my $fasta = readFastx->new();

while(my $seq = $fasta->next_seq){
  if(exists $options{sequence}){
    #this is a hack to make it work for both fasta and fastq easily
    my $temp = $seq->sequence;
    $seq->sequence = $seq->header;
    $seq->header = $temp;
  } elsif(exists $options{length}){
    print length($seq->sequence)."\n";
  } elsif(exists $options{chr}) {
    if($seq->header =~ /[^\s0-9]([0-9]+)/){
      print $1."\n";
    }
  }
  if($seq->isa('readFastx::Fasta::Seq')){
    $seq->print(\*STDOUT,80);
  } else{
  $seq->print;
  }
  print "\0";
}



###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

/home/hesterj/fu/formatForSort.pl - formats a fasta file with the arguments given for processing by gnu sort

=head1 SYNOPSIS

/home/hesterj/fu/formatForSort.pl [options] [file ...]

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

B</home/hesterj/fu/formatForSort.pl> formats a fasta file with the arguments given for processing by gnu sort

=cut

