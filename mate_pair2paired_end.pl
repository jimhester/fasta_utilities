#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/21/2011
# Title:mate_pair2paired_end.pl
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
# mate_pair2paired_end.pl
###############################################################################

use ReadFastx;
my $fastx = ReadFastx->new();
while(my $seq = $fastx->next_seq){
  $seq->sequence(revComp($seq->sequence)); 
  $seq->quality(reverse($seq->quality)); 
  $seq->print;
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

mate_pair2paired_end.pl - 

=head1 SYNOPSIS

mate_pair2paired_end.pl [options] [file ...]

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

B<mate_pair2paired_end.pl> 

=cut

