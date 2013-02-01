#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 07 02:48:11 PM
# Last Modified: 2013 Jan 17 09:57:55 AM
# Title:sort.pl
# Purpose:sort fastx files
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long qw(:config pass_through);
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $length;
my $header;
my $sequence;
my $sequence_size = 100;
my $custom;
GetOptions('length'        => \$length,
           'header'        => \$header,
           'sequence'      => \$sequence,
           'sequence_size' => \$sequence_size,
           'custom=s'      => \$custom,
           man             => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/; $_ } @ARGV;
###############################################################################
# sort.pl
###############################################################################
use ReadFastx;

#child unmerge
unmerge();

#parent
my @sort_args;

push @sort_args, '-n' if($length);

@ARGV = grep {
  if (/^-/) {
    push @sort_args, $_;
    0;
  }
  else {
    $_;
  }
} @ARGV;

open STDOUT, "| sort -z @sort_args";

my $fastx = ReadFastx->new();
while (my $seq = $fastx->next_seq) {
  my $sort_term =
      $length ? length($seq->sequence)
    : $header ? $seq->header
    : $sequence ? substr($seq->sequence, 0, $sequence_size)
    : $custom   ? eval "$custom"
    :             die "Must provide a sort term";
  die $@ if $@;
  print $sort_term, "\1", $seq->string, "\0";
}

sub unmerge {
  return if my $pid = open(STDOUT, "|-");    # return if parent
  die "cannot fork: $!" unless defined $pid;
  local $/ = "\0";
  while (<STDIN>) {
    my ($search, $record) = split /[\1\0]/;
    print $record;
  }
  exit;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

sort.pl - sort fastx files

=head1 SYNOPSIS

sort.pl [options] [file ...]

Options:
      -header
      -sequence
      -length
      -custom
      -help
      -man               for more info

=head1 OPTIONS

=over 8

B<sort.pl> sort fastx files

Print a brief help message and exits.

=item B<-sequence>

sort by the record sequence.

=item B<-header>

sort by the record header.

=item B<-length>

sort by the sequence length.

=item B<-custom>

sort by the a evaled expression on the $seq object, see examples

=item B<-man>

Prints the manual page and exits.

=back

=head1 EXAMPLES

  All other arguments are passed to gnu/sort

sort by header
  sort.pl input.fa -header

  sort.pl input.fa -sequence

  sort.pl input.fa -length -nr 
=head1 DESCRIPTION

B<sort.pl> sort fastx files

=cut

