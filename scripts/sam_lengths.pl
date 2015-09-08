#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:04/02/2010
# Last Modified: 2012 Dec 24 10:41:40 AM
# Title:sam_lengths.pl
# Purpose:this script gets the sequnece lengths from a sam file
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
###############################################################################
# sam_lengths.pl
###############################################################################

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadSam;
my $sam = ReadSam->new();
while(my $align = $sam->next_align){
  print length($sam->sequence),"\n";
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

sam_lengths.pl - this script gets the sequnece lengths from a sam file

=head1 SYNOPSIS

sam_lengths.pl [options] [file ...]

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

B</home/hesterj/fastaUtilities/sam_lengths.pl> this script gets the sequnece lengths from a sam file

=cut

