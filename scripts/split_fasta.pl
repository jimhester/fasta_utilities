#!/usr/bin/perl
use autodie qw(:all);
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:09/13/2012
# Title:split_fasta.pl
# Purpose:splits a multi fasta file into multiple files, can split in different ways
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $prefix;
my $suffix = '.fa';
my $amount;
my $num;
my $width;
my $force;
GetOptions( 'width=i'  => \$width,
            'suffix=s' => \$suffix,
            'amount=i' => \$amount,
            'num=i'    => \$num,
            'prefix=s' => \$prefix,
            'force'    => \$force,
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
# split_fasta.pl
###############################################################################

if ( not $prefix ) {
  if ( -t STDIN ) {
    ($prefix) = remove_suffix($ARGV[0]);
    $prefix .= '_';
  }
  else {
    $prefix = '';
  }
}

use ReadFastx;

my $fastx = ReadFastx->new();
my $OUT;

if ($num) {
  my @seqs;
  my $count = 0;
  my $itr   = 0;
  while ( my $rec = $fastx->next_seq ) {
    if ( $count > $num ) {
      print_array("$prefix$itr$suffix", \@seqs);
      @seqs  = ();
      $count = 0;
      $itr++;
    }
    push @seqs, $rec;
    $count++;
  }

  #print the rest
  $itr++;
  if ( $count > $num ) {
    print_array("$prefix$itr$suffix", \@seqs);
  }
}
elsif ($amount) {
  my @seqs;
  my $size = 0;
  while ( my $rec = $fastx->next_seq ) {
    push @seqs, $rec;
    $size += length( $rec->sequence );
  }
  my $split_size = $size / $amount;
  my $cur_size   = 0;
  my $cutoff     = 0;
  my $itr        = 0;
  my $prev_itr = 0;
  for my $itr (0..$#seqs) {
    if ( $cur_size >= $cutoff ) {
      print_array("$prefix$itr$suffix", \@seqs[$prev_itr..$itr]);
      $prev_itr = $itr+1;
      $cutoff += $split_size;
    }
    $cur_size += length( $seqs[$itr]->sequence );
  }
  print_array("$prefix$itr$suffix", \@seqs[$prev_itr..$#seqs]) if $prev_itr < $#seqs;
}
else {
  while ( my $seq = $fastx->next_seq ) {
    print_array("$prefix" . $seq->header . "$suffix", [ $seq ] );
  }
}

sub print_array{
  my ($filename, $seq_ref) = @_;
  die "$filename exists, use -force to overwrite" if -e $filename and not $force;
  open $OUT, ">$filename";
  for my $seq(@{ $seq_ref }){
    $seq->print( fh => $OUT, width => $width );
  }
  close $OUT;
  #autoflush output
  $|=1;
  print "$filename\n";
}

sub remove_suffix{
  my ($filename) = @_;
  $filename =~ s/[.] [^.]* $//x;
  return $filename;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

split_fasta.pl - splits a multi fasta file into multiple files, can split in different ways

=head1 SYNOPSIS

split_fasta.pl [options] [file ...]

Options:
      -force
      -num
      -prefix
      -suffix
      -width
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-force>

force overwriting of existing files

=item B<-amount>

the amount of files to split the input into, default is one file per record

=item B<-num>

the number of records per file

=item B<-prefix>

prefix for the output files <>

=item B<-suffix>

suffix for the output files <.fa>

=item B<-width>

width to wrap fasta lines, default is no wrap, common is 80

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<split_fasta.pl> splits a multi fasta file into multiple files, can split in different ways

=cut

