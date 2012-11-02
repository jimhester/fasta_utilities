#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/18/2010
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

local $/ = \1;
my $firstChar = <>;
if($firstChar ne "@"){
  die "$ARGV does not look like a fastq file\n";
}
$/ = "@";
while(<>){
  chomp;
  if(/^(.*?)\n(.*?)\+/s){
    my ($header, $sequence) = ($1,$2);
    print ">$header\n$sequence";
  }
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

