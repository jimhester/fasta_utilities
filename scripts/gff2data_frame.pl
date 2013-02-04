#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 15 01:48:27 PM
# Last Modified: 2013 Jan 15 02:12:02 PM
# Title:gff2data_frame.pl
# Purpose:Convert a gff file to a data frame file for import into R
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $gff_version = 3;
GetOptions('help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# gff2data_frame.pl
###############################################################################

my @lines;
my %attribute_fields;
my @colnames = qw(seqid source type start end score strand phase);

while(<>){
  next if /^#/;
  last if /^##FASTA/;
  chomp;
  my $itr = 0;
  my %line;
  my $attributes;
  for my $field(split /\t/){
    if($itr < @colnames){
      $line{$colnames[$itr]}=$field;
    }
    else {
      $attributes .= $field;
    }
    $itr++;
  }
  if($attributes){
    while($attributes =~ m{([^=]+)=([^;]+)}g){
      my($tag,$value) = ($1,$2);
      $attribute_fields{$tag}++;
      $line{attributes}{$tag}=$value;
    }
  }
  push @lines, \%line;
}

my @sorted_attributes = sort keys %attribute_fields;

print join("\t", @colnames, @sorted_attributes),"\n";
for my $line(@lines){
  print join("\t", get_values($line,\@colnames), get_values($line->{attributes}, \@sorted_attributes)),"\n";
}

sub get_values{
  my($array_ref, $keys_ref) = @_;
  map{ exists $array_ref->{$_} ? $array_ref->{$_} : 'NA' } @{ $keys_ref };
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

gff2data_frame.pl - Convert a gff file to a data frame file for import into R

=head1 SYNOPSIS

gff2data_frame.pl [options] [file ...]

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

B<gff2data_frame.pl> Convert a gff file to a data frame file for import into R

=cut

