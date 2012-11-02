#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/09/2010
# Title:cpgCount.pl
# Purpose:this script counts the number of CpGs in a fasta file
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
# cpgCount.pl
###############################################################################

local $/ = ">";
my $first = <>;
while(<>){
  if(/^(.+?)\n(.+?)$/s){
    my($header,$sequence) = ($1,$2);
    $sequence =~ tr/\n//d;
    my($count) = $sequence =~ s/CG/CG/gi;
    $count = 0 if not $count;
    print "$header\t$count\n";
  }
}
###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

cpgCount.pl - this script counts the number of CpGs in a fasta file

=head1 SYNOPSIS

cpgCount.pl [options] [file ...]

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

B<cpgCount.pl> this script counts the number of CpGs in a fasta file

=cut

