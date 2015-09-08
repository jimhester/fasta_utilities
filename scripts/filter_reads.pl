#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2012 Dec 21 10:47:32 AM
# Last Modified: 2013 Jul 29 03:23:47 PM
# Title:filter_reads.pl
# Purpose:given reads and a database, filters the reads which do not map, can
# also keep the database of reads
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long qw(:config pass_through no_auto_abbrev);
use Pod::Usage;
my $man       = 0;
my $help      = 0;
my $num_cores = no_of_cores_gnu_linux();
my $keep_align;
my $only_mapped;
my $prefix;
my $log_file;
GetOptions(
          'log=s' => \$log_file,
          'keep'   => \$keep_align,
           'np|j=i' => \$num_cores,
           'help|?' => \$help,
           'prefix=s' => \$prefix,
           man      => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: Incorrect number of arguments.") if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
###############################################################################
# filter_reads.pl
###############################################################################

my $log_fh = log_fh();

use Carp;
use FindBin;
use lib $FindBin::RealBin."/../";
use ReadSam;

my $index = shift;

my @files = parse_files();

@ARGV = qw(--local --very-sensitive-local) unless @ARGV;

print STDERR "running bowtie with @ARGV\n";

if (@files == 2) {
  run_paired(\@files);
}
else {
  run_single(\@files);
}
exit;

#if log_file exists, open fh to it, otherwise use STDERR
sub log_fh{
  if($log_file){
    open my $fh, ">", $log_file;
    return $fh;
  }
  return \*STDERR;
}

sub run_paired {
  my ($file1, $file2) = @{$_[0]};
  my ($out1) = $prefix ? $prefix.'-1-unmapped.fastq.gz' : '';
  my ($out2) = $prefix ? $prefix.'-2-unmapped.fastq.gz' : '';
  my %counts;

  my $cores = int($num_cores / 2);

  my $sam1   = ReadSam->new(files => ["bowtie2 @ARGV -p $cores --reorder -x $index -U $file1 |"]);
  my $fastq1 = fastq_out($file1, $out1);
  my $sam2   = ReadSam->new(files => ["bowtie2 @ARGV -p $cores --reorder -x $index -U $file2 |"]);
  my $fastq2 = fastq_out($file2, $out2);

  my $bam_out;
  if ($keep_align) {
    my $bam_out_file = $prefix ? $prefix . '-mapped.bam' : '';
    $bam_out = bam_out($file1, $bam_out_file);
    print $bam_out $sam1->header()->raw;
  }
  while (    defined(my $align1 = $sam1->next_align)
         and defined(my $align2 = $sam2->next_align))
  {
    if ($align1->flag & 0x4 and $align2->flag & 0x4) {    #both unmapped
      print $fastq1 $align1->fastq;
      print $fastq2 $align2->fastq;
    }
    else {
      if ($keep_align) {
        print $bam_out $align1->raw;
        print $bam_out $align2->raw;
      }
      $counts{$align1->rname}++;
      $counts{$align2->rname}++;
    }
    $counts{total}+=2;
  }
  print_counts(\%counts, $log_fh);
  close $bam_out if $keep_align;
}

sub print_counts{
  my($count_ref, $fh) = @_;
  $fh = \*STDOUT unless $fh;
  my $sum=0;
  for my $chr( grep { !/total/ } keys_descending($count_ref)){
    print $fh join("\t", $chr, percent_string($count_ref->{$chr}, $count_ref->{total})), "\n";
    $sum+=$count_ref->{$chr};
  }
  print $fh "unmapped\t" , percent_string($count_ref->{total}-$sum,$count_ref->{total}),"\n";
  print $fh "total\t" , percent_string($count_ref->{total},$count_ref->{total}),"\n";
}
sub percent_string{
  my($count, $total) = @_;
  return sprintf "%i\t%.2f%%", $count, $count / $total * 100;
}
sub keys_descending {
  my($hash_ref) = @_;
  return reverse sort  { $hash_ref->{$a} <=> $hash_ref->{$b} } keys %{ $hash_ref };
}
sub run_single {
  my ($file) = @{$_[0]};
  $file = "/dev/stdin" if not $file;
  my $sam = ReadSam->new(files => ["bowtie2 @ARGV -p $num_cores -x $index -U $file |"]);
  my $bam_out;
  my %counts;
  if ($keep_align) {
    my $bam_out_file = $prefix ? $prefix . '-mapped.bam' : '';
    $bam_out = bam_out($file, $bam_out_file);
    print $bam_out $sam->header()->raw;
  }
  while (my $align = $sam->next_align) {
    if ($align->flag & 0x4) {    #unmapped
      print $align->fastq;
    }
    else{
      print $bam_out $align->raw if $keep_align;
      $counts{$align->rname}++;
    }
    $counts{total}++;
  }
  print_counts(\%counts, $log_fh);
  close $bam_out if $keep_align;
}

sub fastq_out {
  my ($file, $new_filename) = @_;
  $new_filename = replace_extension($file, "-unmapped.fastq.gz") unless $new_filename;
  die "$new_filename exists" if -e $new_filename;
  open my $out, "| pigz > $new_filename" or die "$!:Could not open $new_filename";
  return $out;
}

sub bam_out {
  my ($file, $new_filename) = @_;
  $new_filename = replace_extension($file, "-mapped.bam") unless $new_filename;
  die "$new_filename exists" if -e $new_filename;
  open my $out, "| samtools view -S - -b -o $new_filename" or die "$!:Could not open $new_filename";
  return $out;
}

sub replace_extension {
  my ($file, $replace) = @_;
  $file =~ s{\..*}{$replace};    #remove existing extension
  return $file;
}

sub parse_files {
  my @files;
  my @opts;
  for my $arg (@ARGV) {
    if ($arg =~ /^-/) {
      push @opts, $arg;
    }
    else {
      push @files, $arg;
    }
  }
  @ARGV = @opts;
  return @files;
}

sub no_of_cores_gnu_linux {

  # Returns:
  #   Number of CPU cores on GNU/Linux
  my $no_of_cores;
  if (-e "/proc/cpuinfo") {
    $no_of_cores = 0;
    open(IN, "cat /proc/cpuinfo|") || return undef;
    while (<IN>) {
      /^processor.*[:]/ and $no_of_cores++;
    }
    close IN;
  }
  return $no_of_cores;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

filter_reads.pl - given reads and a database, filters the reads which do not map, can 
# also keep the database of reads

=head1 SYNOPSIS

filter_reads.pl [options] [file ...]

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

B<filter_reads.pl> given reads and a database, filters the reads which do not map, can 
# also keep the database of reads

=cut

