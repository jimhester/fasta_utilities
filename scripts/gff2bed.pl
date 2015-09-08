#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 21 09:39:48 AM
# Last Modified: 2013 May 29 09:31:48 AM
# Title:gff2bed.pl
# Purpose:converts gff3 to bed files, either simple or extended
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $extended;
my $color     = "255,0,0";
my $group_var = "Parent";
my $type_filter;
my $gtf;
GetOptions( 'color=s', \$color,
            'extended' => \$extended,
            'filter=s' => \$type_filter,
            'group=s'  => \$group_var,
            'gtf' => \$gtf,
            'help|?'   => \$help,
            man        => \$man )
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
# gff2bed.pl
###############################################################################

my %genes = $gtf ? parse_gtf() : parse_gff();

if ($extended) {
  extended_bed();
}
else {
  simple_bed();
}

sub extended_bed {
  my ($fh) = shift || \*STDOUT;
  for my $chromosome ( keys %genes ) {
    for my $gene_name ( keys %{ $genes{$chromosome} } ) {
      my $gene_start;
      my $gene_end = -1;
      my $gene_score;
      my $gene_strand;

      my @block_sizes;
      my @block_starts;

      for my $exon ( sort { $a->{start} <=> $b->{start} }
                     @{ $genes{$chromosome}{$gene_name} } )
      {
        unless ($gene_start) {
          $gene_start  = $exon->{start};
          $gene_score  = $exon->{score};
          $gene_strand = $exon->{strand};
        }
        $gene_end = $exon->{end} if $exon->{end} > $gene_end;

        my $block_start = $exon->{start} - $gene_start;
        push @block_starts, $block_start;
        my $block_size = $exon->{end} - $exon->{start};
        push @block_sizes, $block_size;
      }
      print $fh join( "\t",
                      $chromosome, $gene_start,
                      $gene_end,   $gene_name,
                      $gene_score, $gene_strand,
                      $gene_start, $gene_end,
                      $color,      scalar(@block_sizes),
                      join( ',', @block_sizes ), join( ',', @block_starts ) ),
        "\n";
    }
  }
}

sub simple_bed {
  my ($fh) = shift || \*STDOUT;
  for my $chromosome ( keys %genes ) {
    for my $gene_name ( keys %{ $genes{$chromosome} } ) {
      for my $exon ( @{ $genes{$chromosome}{$gene_name} } ) {
        print $fh join( "\t",
                        $chromosome, $exon->{start}, $exon->{end},
                        $gene_name,  $exon->{score}, $exon->{strand} ),
          "\n";
      }
    }
  }
}

sub parse_gtf {

  my @colnames = qw(seqid source type start end score strand phase);

  my %genes;

  use FindBin;
  use lib $FindBin::RealBin."/../";
  use FileBar;
  my $bar = FileBar->new();
  while (<>) {
    next if /^#/;
    chomp;
    my $itr = 0;
    my %line;
    my $attributes;
    for my $field ( split /\t/ ) {
      if ( $itr < @colnames ) {
        $field-- if ( $colnames[$itr] eq 'start' );    #make 0 based
        $line{ $colnames[$itr] } = $field;
      }
      else {
        $attributes .= $field;
      }
      $itr++;
    }
    if ($attributes) {
      while ( $attributes =~ m{([^"\s]+)[\s"]+([^"]*)"[^;]*;*}g ) {
        my ( $tag, $value ) = ( $1, $2 );
        $line{attributes}{$tag} = $value;
      }
    }
    my $group_val =
      exists $line{attributes}{$group_var}
      ? $line{attributes}{$group_var}
      : 'NA';

    if(not $type_filter or $type_filter eq $line{type}){
      push @{ $genes{ $line{seqid} }{$group_val} }, \%line;
    }
  }
  return %genes;
}
sub parse_gff {
  my @colnames = qw(seqid source type start end score strand phase);

  my %genes;

  use FileBar;
  my $bar = FileBar->new();
  while () {
    last if /^##FASTA/;
    next if /^#/;
    chomp;
    my $itr = 0;
    my %line;
    my $attributes;
    for my $field ( split /\t/ ) {
      if ( $itr < @colnames ) {
        $field-- if ( $colnames[$itr] eq 'start' );    #make 0 based
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

    if(not $type_filter or $type_filter eq $line{type}){
      push @{ $genes{ $line{seqid} }{$group_val} }, \%line;
    }
  }
  return %genes;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

gff2bed.pl - converts gff3 to bed files, either simple or extended

=head1 SYNOPSIS

gff2bed.pl [options] [file ...]

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-color>

select the color of the extended bed file

=item B<-extended>

use extended bed format rather than simple

=item B<-filter>

filter bed records for a field type

=item B<-group>

grouping optional field to use

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<gff2bed.pl> converts gff3 to bed files, either simple or extended

=cut

