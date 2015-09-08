#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 Mar 26 02:08:36 PM
# Last Modified: 2013 Apr 26 02:46:37 PM
# Title:grep.pl
# Purpose:search a fasta file for a pattern
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my %args = ();
GetOptions( \%args, 'paired=s', 'count|c', 'reverse', 'location|position',
            'help|?', 'man' )
  or pod2usage(2);
pod2usage(2) if exists $args{help};
pod2usage( -verbose => 2 ) if exists $args{man};
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
# grep.pl
###############################################################################
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

my $search_term = shift;

if ( exists $args{reverse} ) {
  $search_term = reverse_complement($search_term);
}

my $count  = 0;
if ( exists $args{paired} ) {
  die "please specify 2 files when using paired\n" unless @ARGV == 2;
  my $fastx1 = ReadFastx->new(shift);
  my $fastx2 = ReadFastx->new(shift);
  while ( my $seq1 = $fastx1->next_seq and my $seq2 = $fastx2->next_seq ) {
    my $sequence_1 = $seq1->sequence;
    my $sequence_2 = $seq2->sequence;
    if ( $sequence_1 =~ /$search_term/ ) {
      my ( $match_start_1, $match_end_1 ) = ( $-[0], $+[0] );
      if ( $sequence_2 =~ /$args{paired}/ ) {
        my ( $match_start_2, $match_end_2 ) = ( $-[0], $+[0] );
        if ( exists $args{count} ) {
          $count++;
        }
        elsif ( exists $args{location} ) {
          print join( "\t",
                      $seq1->header,  $match_start_1, $match_end_1,
                      $match_start_2, $match_end_2 ),
            "\n";
        }
        else {
          $seq1->print;
          $seq2->print;
        }
      }
    }
  }
}
else {
  my $fastx = ReadFastx->new();
  my $count = 0;
  while ( my $seq = $fastx->next_seq ) {
    my $sequence = $seq->sequence;
    while ( $sequence =~ /$search_term/g ) {
      if ( exists $args{count} ) {
        $count++;
      }
      elsif ( exists $args{location} ) {
        my ( $match_start, $match_end ) = ( $-[0], $+[0] );
        print $seq->header, "\t$match_start\t$match_end\n";
      }
      else {
        $seq->print;
      }
    }
  }
}

print $count, "\n" if exists $args{count};

sub reverse_complement {
  my ($in) = @_;
  $in =~ tr/ACGTacgt/TGCAtgca/;
  $in = reverse($in);
  return ($in);
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

grep.pl - search a fasta file for a pattern

=head1 VERSION

0.0.1

=head1 USAGE

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<grep.pl>  search a fasta file for a pattern

=cut

