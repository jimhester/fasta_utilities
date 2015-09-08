#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 Jan 07 02:48:11 PM
# Last Modified: 2013 Aug 14 12:22:10 PM
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
my $sequence_size;
my $custom;
my $paired;
my $prefix;
my $force;
GetOptions( 
  'force' => \$force,
            'prefix=s' => \$prefix,
            'paired' => \$paired,
            'length'        => \$length,
            'header'        => \$header,
            'sequence'      => \$sequence,
            'sequence_size=i' => \$sequence_size,
            'custom=s'      => \$custom,
            man             => \$man )
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
# sort.pl
###############################################################################
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

#child process unmerge
if($paired){
  paired_unmerge();
}else{
  single_unmerge();
}

#parent
my @sort_args;

push @sort_args, '-n' if ($length);

@ARGV = grep {
  if (/^-/) {
    push @sort_args, $_;
    0;
  }
  else {
    $_;
  }
} @ARGV;


if($paired){
  paired();
}else{
  single();
}
exit;

sub single{
  my $key = get_key();

  open STDOUT, "| sort -k$key,$key -t '\t' @sort_args";

  my $fastx = ReadFastx->new();
  while ( my $seq = $fastx->next_seq ) {
    my $sort_term = get_sort_term($seq);
    my $quality = $seq->can('quality') ? $seq->quality : '';
    print join( "\t", $sort_term, $seq->header, $seq->sequence, $quality ),
      "\n";
  }
}
sub paired{
  my $key = get_key();
  my $key2 = $key + 4;

  my($file1, $file2) = @ARGV;

  pod2usage("$0:cannot use --paired without explicit files") unless $file2;

  open STDOUT, "| sort -k$key,$key -k$key2,$key2 -t '\t' @sort_args";

  my $fastx1 = ReadFastx->new($file1);
  my $fastx2 = ReadFastx->new($file2);
  while ( my $seq1 = $fastx1->next_seq
     and my $seq2 = $fastx2->next_seq ) {
    my $sort_term1 = get_sort_term($seq1);
    my $sort_term2 = get_sort_term($seq2);
    my $quality1 = $seq1->can('quality') ? $seq1->quality : '';
    my $quality2 = $seq2->can('quality') ? $seq2->quality : '';
    print join( "\t", $sort_term1, $seq1->header, $seq1->sequence, $quality1
    , $sort_term2, $seq2->header, $seq2->sequence, $quality2),
      "\n";
  }
}

sub get_sort_term {
  my ($seq) = @_;
  return '' if $sequence or $header;
  return length( $seq->sequence ) if $length;
  return substr( $seq->sequence, 0, $sequence_size ) if $sequence_size;
  return eval "$custom" if $custom;
  pod2usage("$0: Must provide a sort term");
}

sub get_key {
  return 1 if $length or $custom;
  return 2 if $header;
  if ($sequence) {
    return 1 if $sequence_size;
    return 3;
  }
  pod2usage("$0: Must provide a sort term");
}

sub paired_unmerge {
  return if my $pid = open( STDOUT, "|-" );    # return if parent
  die "cannot fork: $!" unless defined $pid;

  my($file1, $file2) = @ARGV;

  pod2usage("$0:cannot use --paired without explicit files") unless $file2;

  open my $out1, ">", generate_filename($file1,'sorted');
  open my $out2, ">", generate_filename($file2,'sorted');

  while (<STDIN>) {
    chomp;
    my ( $search, $header, $sequence, $quality,
         $search2, $header2, $sequence2, $quality2
    ) = split /\t/;
    if ($quality) {
      ReadFastx::Fastq->new( header   => $header,
                             sequence => $sequence,
                             quality  => $quality )->print(fh=>$out1);
      ReadFastx::Fastq->new( header   => $header2,
                             sequence => $sequence2,
                             quality  => $quality2 )->print(fh=>$out2);
    }
    elsif ($header) {
      ReadFastx::Fasta->new( header => $header, sequence => $sequence )
        ->print(fh => $out1);
      ReadFastx::Fasta->new( header => $header2, sequence => $sequence2 )
        ->print(fh => $out2);
    }
  }
  exit;
}

sub single_unmerge {
  return if my $pid = open( STDOUT, "|-" );    # return if parent
  die "cannot fork: $!" unless defined $pid;
  while (<STDIN>) {
    chomp;
    my ( $search, $header, $sequence, $quality ) = split /\t/;
    if ($quality) {
      ReadFastx::Fastq->new( header   => $header,
                             sequence => $sequence,
                             quality  => $quality )->print();
    }
    elsif ($header) {
      ReadFastx::Fasta->new( header => $header, sequence => $sequence )
        ->print();
    }
  }
  exit;
}

sub generate_filename{
  my($filename, $new) = @_;

  my($local_prefix, $suffix) = $filename =~ m{(.+)[.](.*)};

  $local_prefix = $prefix if $prefix;
  my $newfile = "$local_prefix.$new.$suffix";
  die "$newfile exists" if -e $newfile and not $force;
  return $newfile;
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

