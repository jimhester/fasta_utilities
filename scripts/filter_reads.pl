#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2012 Dec 21 10:47:32 AM
# Last Modified: 2012 Dec 31 12:25:00 PM
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
GetOptions('keep'   => \$keep_align,
           'np|j=i' => \$num_cores,
           'help|?' => \$help,
           man      => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: Incorrect number of arguments.") if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/; $_ } @ARGV;
###############################################################################
# filter_reads.pl
###############################################################################

use Carp;
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

sub run_paired {
  my ($file1, $file2) = @{$_[0]};
  my $cores = int($num_cores / 2);

  my $sam1   = ReadSam->new(files => ["bowtie2 @ARGV -p $cores --reorder -x $index -U $file1 |"]);
  my $fastq1 = fastq_out($file1);
  my $sam2   = ReadSam->new(files => ["bowtie2 @ARGV -p $cores --reorder -x $index -U $file2 |"]);
  my $fastq2 = fastq_out($file2);

  my $bam_out;
  if ($keep_align) {
    $bam_out = bam_out($file1);
    print $bam_out $sam1->header()->raw;
  }
  while (    defined(my $align1 = $sam1->next_align)
         and defined(my $align2 = $sam2->next_align))
  {
    if ($align1->flag & 0x4 and $align2->flag & 0x4) {    #both unmapped
      print $fastq1 $align1->fastq;
      print $fastq2 $align2->fastq;
    }
    if ($keep_align) {
      print $bam_out $align1->raw;
      print $bam_out $align2->raw;
    }
  }
  close $bam_out if $keep_align;
}

sub run_single {
  my ($file) = @{$_[0]};
  $file = "/dev/stdin" if not $file;
  my $sam = ReadSam->new(files => ["bowtie2 @ARGV -p $num_cores -x $index -U $file |"]);
  my $bam_out;
  if ($keep_align) {
    $bam_out = bam_out($file);
    print $bam_out $sam->header()->raw;
  }
  while (my $align = $sam->readline) {
    if ($align->flag & 0x4) {    #unmapped
      print $align->fastq;
    }
    print $bam_out $align->raw if $keep_align;
  }
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
  $file =~ s{\..*}{};    #remove existing extension
  $file .= "$replace";
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

