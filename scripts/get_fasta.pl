#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# Title:get_fasta.pl
# Created: 2012 Oct 23 03:40:48 PM
# Modified: 2014 Mar 27 01:24:41 PM
# Purpose:gets fasta with the given headers
# By Jim Hester
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $search_file;
my $reverse;
my $exact;
GetOptions('exact'     => \$exact,
           'reverse|v' => \$reverse,
           'f=s'       => \$search_file,
           'help|?'    => \$help,
           man         => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/; $_ } @ARGV;
###############################################################################
# get_fasta.pl
###############################################################################
my @search;

use List::MoreUtils qw(any);

my %search = map { $_ => '' } ($search_file ? read_search_file($search_file) : split(/,/, shift));

use ReadFastx;
my $fastx = ReadFastx->new();
while (my $seq = $fastx->next_seq) {
  my $found = $exact ? find_exact($seq->header) : find_regex($seq->header);
  $found = not $found if $reverse;
  $seq->print if $found;
}

sub read_search_file{
  my ($filename) = @_;
  my @vals;
  open IN, "$filename" or die "$!:Could not open $filename\n";
  while (<IN>) {
    chomp;
    push @vals, $_;
  }
  return @vals;
}

sub find_exact{
  my($header) = @_;

  return exists $search{$header}
}

sub find_regex{
  my($header) = @_;

  return any { $header =~ /$_/ } keys %search;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

get_fasta.pl - gets fasta with the given headers

=head1 SYNOPSIS

get_fasta.pl [options] [file ...]

Options:
      -exact
      -reverse
      -f
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-exact>

Exact matching only

=item B<-reverse>

Output only sequences which do not match

=item B<-f>

File with search terms

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<get_fasta.pl> gets fasta with the given headers

=cut

