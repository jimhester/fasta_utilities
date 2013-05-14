#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 May 13 11:56:06 AM
# Last Modified: 2013 May 14 03:14:05 PM
# Title:collapse_duplicates.pl
# Purpose:Collapse duplicate reads, keeping reads counts
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my %args = ();
GetOptions(\%args,'length=i', 'force', 'prefix=s', 'paired', 'help|?', 'man') or pod2usage(2);
pod2usage(2) if exists $args{help};
pod2usage(-verbose => 2) if exists $args{man};
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# collapse_duplicates.pl
###############################################################################

my $sort_args = exists $args{length} ? "--sequence_size $args{length} --sequence" : "--sequence";
if(exists $args{paired}){
  paired();
}
else {
  single();
}

sub single{
  open my ($fh), "sort.pl $sort_args @ARGV |";

  use ReadFastx;
  my $fastx = ReadFastx->new(fh => $fh);
  my $prev = $fastx->next_seq;
  my $count = 1;
  while(my $seq = $fastx->next_seq){
    if(test_sequence($prev) ne test_sequence($seq)){
      $prev->header($prev->header . ":$count");
      $prev->print();
      $count=0;
    }
    $prev=$seq;
    $count++;
  }
  $prev->header($prev->header . ":$count");
  $prev->print();
}

sub paired{
  my ($file1, $file2) = @ARGV;

  my $sorted_file1 = generate_filename($file1, "sorted");
  my $sorted_file2 = generate_filename($file2, "sorted");

  #make named pipes for the sorted files
  use POSIX qw(mkfifo);
  mkfifo($sorted_file1, 0700);
  mkfifo($sorted_file2, 0700);

  open my $file1_out, ">", generate_filename($file1,"collapsed");
  open my $file2_out, ">", generate_filename($file2,"collapsed");

  system("sort.pl $sort_args --paired --force $file1 $file2 &");

  open my ($file1_in), $sorted_file1;
  open my ($file2_in), $sorted_file2;

  use ReadFastx;
  my $fastx1 = ReadFastx->new(fh => $file1_in);
  my $fastx2 = ReadFastx->new(fh => $file2_in);
  my $prev1 = $fastx1->next_seq;
  my $prev2 = $fastx2->next_seq;
  my $count = 1;
  while(my $seq1 = $fastx1->next_seq
      and my $seq2 = $fastx2->next_seq){
    if((test_sequence($prev1) . test_sequence($prev2)) ne (test_sequence($seq1) . test_sequence($seq2))){
      $prev1->header($prev1->header . ":$count");
      $prev2->header($prev2->header . ":$count");
      $prev1->print(fh=>$file1_out);
      $prev2->print(fh=>$file2_out);
      $count=0;
    }
    $prev1=$seq1;
    $prev2=$seq2;
    $count++;
  }
  $prev1->header($prev1->header . ":$count");
  $prev1->print(fh=>$file1_out);
  $prev2->header($prev2->header . ":$count");
  $prev2->print(fh=>$file2_out);

  unlink $sorted_file1;
  unlink $sorted_file2;
  close $file1_out;
  close $file2_out;
}

sub test_sequence{
  my($seq) = @_;
  return exists $args{length} ? substr($seq->sequence, 0, $args{length}) : $seq->sequence;
}
sub generate_filename{
  my($filename, $new) = @_;

  my($local_prefix, $suffix) = $filename =~ m{(.+)[.](.*)};

  $local_prefix = $args{prefix} if exists $args{prefix};
  my $newfile = "$local_prefix.$new.$suffix";
  die "$newfile exists" if -e $newfile and not exists $args{force};
  return $newfile;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

collapse_duplicates.pl - Collapse duplicate reads, keeping reads counts

=head1 VERSION

0.0.1

=head1 USAGE

Options:
      -force
      -paired
      -prefix
      -help
      -man               for more info

=head1 OPTIONS

=over

=item B<-force>

Force writing even if a file exists.

=item B<-paired>

Collapse using paired ends.

=item B<-prefix>

Prefix to use for output files, only applicable for paired end.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<collapse_duplicates.pl> Collapse duplicate reads, keeping reads counts

=cut

