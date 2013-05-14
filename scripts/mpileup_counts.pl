#!/usr/bin/perl
use warnings;
use strict;
use autodie;
###############################################################################
# Title:mpileup_counts.pl
# Created: 2012 Oct 26 08:28:19 AM
# Modified: 2013 Apr 04 09:31:02 AM
# Purpose:parses a mpileup file and gets the basecounts
# By Jim Hester
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
GetOptions( 'help|?' => \$help, man => \$man ) or pod2usage(2);
pod2usage(2) if $help;
pod2usage( -verbose => 2 ) if $man;
pod2usage("$0: No files given.") if ( ( @ARGV == 0 ) && ( -t STDIN ) );

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map {
  s/(.*\.gz)\s*$/pigz -dc < $1|/;
  s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;
  $_
} @ARGV;
###############################################################################
# mpileup_counts.pl
###############################################################################
use Carp;

#setup and print headers
my @bases = qw(A C G T N);
print join( "\t",
            "chromosome", "position", "coverage", "reference",
            "raf", @bases )
  . "\n";

my %sequences;
while (<>) {

  #parse mpileup
  my ( $chr, $pos, $ref, $coverage, $reads, $qualities ) = split;
  $sequences{$chr}{last} = 0
    unless exists $sequences{$chr};    # initialize last position
  my $starts = $reads =~ s/\^.//g;     #remove read starts and mapping quality
  my $ends   = $reads =~ s/\$//g;      #remove read ends
  my $indels = $reads =~ s/[\+\-]([0-9]+)(??{"\\w{$^N}"})//g;   #remove indels
  my $skip    = $reads =~ s/[<>]//g;    #remove reference skips
  my $deleted = $reads =~ s/[*]//g;
  $reads = uc $reads;                   #make all letters uppercase
  $reads =~ s/[.,]/$ref/g;              #change ref bases to ref letter

  #get counts for bases
  my %counts;
  my $total;
  for my $base (@bases) {
    my $count = $reads =~ s/$base/$base/g;
    $counts{$base} = $count ? $count : 0;
    $total += $count;
  }
  $total += $skip + $deleted;
  if ( $total != $coverage ) {
    croak sprintf
      "starts:%i ends:%i indels:%i skip:%i deleted:%i $total is not equal to $coverage on the following line\n$_",
      $starts, $ends, $indels, $skip, $deleted;
  }

  #print data
  print join( "\t",
              $chr, $pos, $coverage, $ref,
              sprintf( "%2f", $counts{$ref} / $total ),
              map { $counts{$_} } @bases ),
    "\n";
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

mpileup_counts.pl - parses a mpileup file and gets the basecounts

=head1 SYNOPSIS

mpileup_counts.pl [options] [file ...]

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

B<mpileup_counts.pl> parses a mpileup file and gets the basecounts

=cut

