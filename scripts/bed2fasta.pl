#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 Apr 04 03:21:27 PM
# Last Modified: 2013 Apr 05 08:20:56 AM
# Title:bed2fasta.pl
# Purpose: Given a bed file and a fasta file, get the corresponding, optionally spliced fasta
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my %args = ();
GetOptions(\%args, 'name', 'splice', 'help|?', 'man') or pod2usage(2);
pod2usage(2) if exists $args{help};
pod2usage(-verbose => 2) if exists $args{man};
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# bed2fasta.pl
###############################################################################
use Carp;

use Readonly;
Readonly my @bed12_fields => qw(chromosome start end name score strand thick_start thick_end rgb block_count block_size block_start);

my %regions;
my $bed_file = shift;
open my($bed), "<", "$bed_file";
while(<$bed>){
  #bed12 description
  my $bed = read_bed($_);
  if(exists $args{splice}){
    croak "--splice given but not bed12 format" unless exists $bed->{block_count};
  }
  push @{ $regions{$bed->{chromosome}} }, $bed;
}

use ReadFastx;
my $fastx = ReadFastx->new();
while(my $seq = $fastx->next_seq){
  if(exists $regions{$seq->header}){
    for my $bed( @{ $regions{$seq->header} }){
      my $sequence = substr($seq->sequence, $bed->{start}, $bed->{end}-$bed->{start});
      if(exists $args{splice}){
        my $spliced_sequence;
        for my $block(1..$bed->{block_count}){
          $spliced_sequence .= substr($sequence, $bed->{block_start}[$block-1], $bed->{block_size}[$block-1]);
        }
        $sequence = $spliced_sequence;
      }
      if($bed->{strand} eq '-'){
        $sequence = reverse_complement($sequence);
      }
      my $name = exists $args{name} ?  $bed->{name} : $seq->header;
      print '>', $name, '/', $bed->{start}, '-', $bed->{end}, "\n", $sequence, "\n";
    }
  }
}

sub read_bed{
  my($line) = @_;
  my %bed;
  my $itr = 0;
  for my $value(split ' ', $line){
    croak "improperly formatted bed file" if $itr > $#bed12_fields;
    my $current_field = $bed12_fields[$itr];

    if($current_field eq 'block_size' or $current_field eq 'block_start'){
      $value = [ split /,/, $value ];
    }
    $bed{$current_field}=$value;
    $itr++;
  }
  return \%bed;
}

sub reverse_complement{
  my($in) = @_;
  $in =~ tr/ACGTacgt/TGCAtgca/;
  $in = reverse($in);
  return($in);
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

bed2fasta.pl - Given a bed file and a fasta file, get the corresponding, optionally spliced fasta

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

B<bed2fasta.pl> Given a bed file and a fasta file, get the corresponding, optionally spliced fasta

=cut

