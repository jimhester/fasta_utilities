#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2012 Dec 10 10:20:30 AM
# Last Modified: 2012 Dec 10 10:24:20 AM
# Title:fetch_entrez.pl
# Purpose:Download a number of sequences from an entrez query
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $fetch_size=500;
GetOptions('fetch_size|s' => \$fetch_size,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: Please supply an entrez search")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# fetch_entrez.pl
###############################################################################

use LWP::Simple;
my $query = "@ARGV";

#assemble the esearch URL
my $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
my $url = $base . "esearch.fcgi?db=nucleotide&term=$query&usehistory=y";

#post the esearch URL
my $output = get($url);

#parse WebEnv, QueryKey and Count (# records retrieved)
my $web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);
my $key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);
my $count = $1 if ($output =~ /<Count>(\d+)<\/Count>/);

#retrieve data in batches
my $retmax = $fetch_size;
for (my $retstart = 0; $retstart < $count; $retstart += $retmax) {
  my $efetch_url = $base ."efetch.fcgi?db=nucleotide&WebEnv=$web";
  $efetch_url .= "&query_key=$key&retstart=$retstart";
  $efetch_url .= "&retmax=$retmax&rettype=fasta&retmode=text";
  my $efetch_out = get($efetch_url);
  print "$efetch_out";
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

fetch_entrez.pl - Download a number of sequences from an entrez query

=head1 SYNOPSIS

fetch_entrez.pl [options] [file ...]

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

B<fetch_entrez.pl> Download a number of sequences from an entrez query

=cut

