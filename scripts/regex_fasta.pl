#!/usr/bin/perl
use warnings;

#use strict;
###############################################################################
# Title:regex_fasta.pl
# Created: 2012 Oct 08 01:06:35 PM - Jim Hester
# Modified: 2012 Dec 31 12:06:18 PM
# Purpose:reformats the fasta header with the regex given by the first argument
# By Jim Hester
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my @sequence;
my @header;
my $found;
my $width;
GetOptions('width=i'    => \$width,
           'found_only' => \$found,
           'header=s'   => \@header,
           'sequence=s' => \@sequence,
           'help|?'     => \$help,
           man          => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));

@header   = split(/(?<!\\),/, join(",", @header));
@sequence = split(/(?<!\\),/, join(",", @sequence));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/; $_ } @ARGV;
###############################################################################
use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;

#if no arguments are supplied, assume grepping for headers
if (not @header and not @sequence) {
  $found = 1;
  my $term = shift;
  $term = "m{$term}";
  push @header, $term;
}

my $fastx = ReadFastx->new();
while (my $seq = $fastx->next_seq) {
  my $val;
  my ($header, $sequence) = ($seq->header, $seq->sequence);
  for my $regex (@header) {
    eval "\$val = \$header =~ $regex;";
    warn $@ if $@;
  }
  for my $regex (@sequence) {
    eval "\$val = \$sequence =~ $regex;";
    warn $@ if $@;
  }
  $seq->header($header);
  $seq->sequence($sequence);
  $seq->print(width => $width) unless ($found and not $val);
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

regex_fasta.pl - reformats the fasta header with the regex given by the first argument

=head1 SYNOPSIS

regex_fasta.pl [options] [file ...]

Options:
      -found_only
      -header
      -sequence
      -width
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-found_only>

Only print fastx records which have been matched or replaced.

=item B<-header>

Search the fastx headers with the regex supplied.  Can be given more than once, or have terms seperated by commas.  Ex. -header m/chr01/,m/chrM/

=item B<-sequence>

Search the fastx sequence with the regex.  Can be given more than once, or have terms seperated by commas. Ex. -sequence tr/acgt/ACGT/,s/CG/NN/g

=item B<-width>

Size to wrap lines in output

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<regex_fasta.pl> reformats the fasta header with the regex given by the first argument

=cut

