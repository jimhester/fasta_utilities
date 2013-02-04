#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:04/02/2010
# Last Modified: 2012 Dec 24 10:35:53 AM
# Title:sam2fastq.pl
# Purpose:Converts a sam file to fastq file(s)
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $illumina;
my $pair=0;
GetOptions('pair=i' => \$pair, 'illumina|I' => \$illumina,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# sam2fastq.pl
###############################################################################

use ReadSam;
my $sam = ReadSam->new();
while(my $align = $sam->next_align){
  $align->quality( pack("c*", map{ $_ + 64 } $align->quality_array)) if $illumina;
  if($pair == 1){
    $align->qname($align->qname .= "/1");
  }
  if($pair == 2){
    $align->qname($align->qname .= "/2");
  }
  print $align->fastq;
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

sam2fastq.pl - Converts a sam format to fastq format

=head1 SYNOPSIS

sam2fastq.pl [options] [file ...]

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

B</home/hesterj/fastaUtilities/sam2fastq.pl> this script gets the sequnece lengths from a sam file

=cut

