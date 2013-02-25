#!/usr/bin/env perl
use warnings;
use strict;
use autodie;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 31 03:39:58 PM
# Last Modified: 2013 Feb 05 02:54:37 PM
# Title:distances.pl
# Purpose:cluster sequences, and remove outliers
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long qw(:config pass_through);
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $query;
my $nucleotide;
my $top;
GetOptions( 'top'        => \$top,
            'query=s'    => \$query,
            'nucleotide' => \$nucleotide,
            'help|?'     => \$help,
            man          => \$man )
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
# distances.pl
###############################################################################

my $file =
  ( defined $ARGV[0] and $ARGV[0] !~ /^-/ ) ? shift : create_temp_file();

$query = $file unless $query;

my $in = $nucleotide ? open_nucleotide($file) : open_protein($file);

my %scores = process_blast($in);

print_scores( \%scores );

exit;

sub create_temp_file {
  use File::Temp qw(tempfile);
  my ( $out, $out_name ) = tempfile();
  while (<STDIN>) {
    print $out $_;
  }
  close $out;
  print STDERR $out_name;
  return $out_name;
}

sub open_protein {
  my ($file) = @_;
  system("makeblastdb -dbtype prot -in $file -out $file >/dev/null")
    unless -e "$file.psq";
  open my $in, "blastp -query $query -db $file -outfmt 7 @ARGV |";
  return $in;
}

sub open_nucleotide {
  my ($file) = @_;
  system("makeblastdb -dbtype nucl -in $file -out $file")
    unless -e "$file.nsq";
  open my $in, "blastn -query $query -db $file -outfmt 7 @ARGV |";
  return $in;
}

sub process_blast {
  my ($in) = @_;
  my %scores;
  my ( $database, $query );
  while (<$in>) {
    $database = $1 if /# Database: (\S+)/;
    if (/# Query: (\S+)/) {
      $query = $1;
      $scores{$query} = 0;
    }
    if (/^[^#]/) {
      my ( $query_id, $subject_id, $pident, $length,
           $mismatch, $gapopen,    $qstart, $qend,
           $sstart,   $send,       $evalue, $bitscore )
        = split /[\t\n]/;
      if ( $query_id ne $subject_id ) {
        $scores{$query} += $bitscore unless ($top and $scores{$query} != 0);
      }
    }
    print STDERR "\r$." if $. % 100 == 0;
  }
  return %scores;
}

sub print_scores {
  my ($score_ref) = @_;
  for my $query ( reverse sort { $score_ref->{$a} <=> $score_ref->{$b} }
                  keys %{$score_ref} )
  {
    print $query, "\t", $score_ref->{$query}, "\n";
  }
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

distances.pl - cluster sequences, and remove outliers

=head1 SYNOPSIS

distances.pl [options] [file ...]

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

B<distances.pl> cluster sequences, and remove outliers

=cut

