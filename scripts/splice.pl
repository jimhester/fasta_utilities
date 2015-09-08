#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 21 08:16:47 AM
# Last Modified: 2013 Jan 31 08:39:14 AM
# Title:splice.pl
# Purpose:splices a fasta file into genes, given a gff file and a fasta
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man         = 0;
my $help        = 0;
my $type_filter = "CDS";
my $group_var   = "Parent";
my $keep_introns;
GetOptions( 'keep_intron|intron' => \$keep_introns,
            'group=s'            => \$group_var,
            'filter=s'           => \$type_filter,
            'help|?'             => \$help,
            man                  => \$man, )
  or pod2usage(2);
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
# splice.pl
###############################################################################
use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;

my $gff_filename = shift;

my %genes = parse_gff($gff_filename);

my $fastx = ReadFastx->new();
while ( my $seq = $fastx->next_seq ) {
  if ( exists $genes{ $seq->header } ) {
    for my $gene_name ( keys %{ $genes{ $seq->header } } ) {
      my $previous_end = -1;
      my $sequence     = '';
      my $full_sequence = $seq->sequence;
      for my $exon ( @{ $genes{ $seq->header }{$gene_name} } ) {
        if ( $keep_introns and $previous_end != -1 ) {    #intron
          test_length($seq, $exon->{start});
          $sequence .= lc( substr( $full_sequence, $previous_end,
                                   $exon->{start} - $previous_end ) );
        }

        #exon
        test_length($seq, $exon->{end});
        $sequence .= uc( substr( $full_sequence, $exon->{start},
                                 $exon->{end} - $exon->{start} ) );
        $previous_end = $exon->{end};
      }
      if ( $genes{ $seq->header }{$gene_name}[0]->{strand} eq '-' ) {
        $sequence = reverse_complement($sequence);
      }
      my $gene =
        ReadFastx::Fasta->new( header => $gene_name, sequence => $sequence );
      $gene->print( width => 80 );
    }
  }
}

sub test_length{
  my($seq, $position) = @_;
  die "$position is less than 0" if $position < 0;
  die $seq->header, ": $position is greater than ", length($seq->sequence) + 1 if $position > length($seq->sequence) + 1;
}

sub reverse_complement {
  my ($in) = @_;
  $in =~ tr/ACGTacgt/TGCAtgca/;
  $in = reverse($in);
  return ($in);
}

sub parse_gff {
  my ($filename) = @_;

  my @colnames = qw(seqid source type start end score strand phase);

  my %genes;

  open my $in, "<", "$filename" or die "$!:Could not open $filename\n";

  while (<$in>) {
    last if /^##FASTA/;
    next if /^#/;
    chomp;
    my $itr = 0;
    my %line;
    my $attributes;
    for my $field ( split /\t/ ) {
      if ( $itr < @colnames ) {
        last
          if $colnames[$itr] eq 'type'
          and $type_filter
          and $field ne $type_filter;
        $field-- if ( $colnames[$itr] eq 'start');    #make 0 based
        $line{ $colnames[$itr] } = $field;
      }
      else {
        $attributes .= $field;
      }
      $itr++;
    }
    if ($attributes) {
      while ( $attributes =~ m{([^=]+)=([^;]+);*}g ) {
        my ( $tag, $value ) = ( $1, $2 );
        $line{attributes}{$tag} = $value;
      }
    }
    my $group_val =
      exists $line{attributes}{$group_var}
      ? $line{attributes}{$group_var}
      : 'NA';
    push @{ $genes{ $line{seqid} }{$group_val} }, \%line;
  }
  return %genes;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

splice.pl - splices a fasta file into genes, given a gff file and a fasta

=head1 SYNOPSIS

splice.pl [options] [file ...]

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

B<splice.pl> splices a fasta file into genes, given a gff file and a fasta

=cut

