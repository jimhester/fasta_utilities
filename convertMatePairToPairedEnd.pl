#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/21/2011
# Title:convertMatePairToPairedEnd.pl
# Purpose:
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
# convertMatePairToPairedEnd.pl
###############################################################################

local $/ = "@";
my $first = <>;
while(<>){
  if(/^(.+?)\n(.+?)\n\+.+?\n(.+?)\n/s){
    my($header,$sequence,$quality) = ($1,$2,$3);
    print "@",$header,"\n",revComp($sequence),"\n+",$header,"\n",reverse($quality),"\n";
  }
}
sub revComp{
  $_[0] =~ tr/ACGTacgt/TGCAtgca/;
  return(reverse( $_[0]));
}



###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

convertMatePairToPairedEnd.pl - 

=head1 SYNOPSIS

convertMatePairToPairedEnd.pl [options] [file ...]

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

B<convertMatePairToPairedEnd.pl> 

=cut

