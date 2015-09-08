#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 03/18/2010
# Last Modified: 2013 Jan 18 03:57:03 PM
# Title:fastq2fasta.pl
# Purpose:this script converts fastq to fasta
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
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# fastq2fasta.pl
###############################################################################

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;
my $fastx = ReadFastx->new();
while(my $seq = $fastx->next_seq){
  my $fasta = ReadFastx::Fasta->new(sequence => $seq->sequence, header => $seq->header);
  $fasta->print;
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

fastq2fasta.pl - this script converts fastq to fasta

=head1 SYNOPSIS

fastq2fasta.pl [options] [file ...]

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

B<fastq2fasta.pl> this script converts fastq to fasta

=cut

