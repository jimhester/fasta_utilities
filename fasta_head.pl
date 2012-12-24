#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:07/22/2009
# Title:fasta_head.pl
# Purpose:This script emulates unix head for fasta and fastq files
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $max = 10;
my $reverse;
GetOptions('n=i' => \$max, 'r' => \$reverse, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# fasta_head.pl
###############################################################################

use ReadFastx;
my $fastx = ReadFastx->new();
my $count=0;
while($count < $max and defined(my $seq = $fastx->next_seq)){
  $seq->print;
  $count++; 
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

fasta_head.pl - This script emulates unix head for fasta and fastq files

=head1 SYNOPSIS

fasta_head.pl [options] [file ...]

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

B<fasta_head.pl> This script emulates unix head for fasta and fastq files

=cut

