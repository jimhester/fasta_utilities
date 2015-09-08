#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:12/14/2010
# Last Modified: 2013 Feb 05 02:08:40 PM
# Title:size_select.pl
# Purpose:returns the sequences with lengths between the values specified by -low and -high
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $low = 0;
my $high = 10000000000000000;
GetOptions('low=i' => \$low, 'high=i' => \$high, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# size_select.pl
###############################################################################

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;
my $fastx = ReadFastx->new();
while(my $seq = $fastx->next_seq){
  my $seq_length = length($seq->sequence);
  if($seq_length >= $low and $seq_length <= $high){
    $seq->print;
  }
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

size_select.pl - returns the sequences with lengths between the values specified by -low and -high

=head1 SYNOPSIS

size_select.pl [options] [file ...]

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

B<size_select.pl> returns the sequences with lengths between the values specified by -low and -high

=cut

