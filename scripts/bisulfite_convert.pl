#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:07/27/2010
# Last Modified: 2012 Dec 24 10:10:40 AM
# Title:bisulfite_convert.pl
# Purpose:this script bisulfate converts the sequences given to it
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
# bisulfite_convert.pl
###############################################################################

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;
my $fastx = ReadFastx->new();
while(my $seq = $fastx->next_seq){
  my $sequence = $fastx->sequence;
  $sequence =~ tr/Cc/Tt/d;
  $fastx->sequence($sequence);
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

bisulfite_convert.pl - this script bisulfate converts the sequences given to it

=head1 SYNOPSIS

bisulfite_convert.pl [options] [file ...]

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

B<bisulfite_convert.pl> this script bisulfate converts the sequences given to it

=cut

