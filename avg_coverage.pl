#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:09/12/2012
# Title:avg_coverage.pl
# Purpose:gets the average coverage per sequence from a bam file
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $region;
GetOptions('region=s' => \$region, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
#@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc 
#< $1|/;$_ } @ARGV;
###############################################################################
# avg_coverage.pl
###############################################################################
use Statistics::Descriptive;

my $read_size=0;
my %sizes;
my %cov;
my $count=0;
my $name;
print join("\t","file","contig","length","min","mean","median","max","sd")."\n";
for my $filename(@ARGV){
  open READS, "samtools view $filename |";
  $read_size=0;
  my %read_sizes;
  while(<READS>){
    my($qname,$flag,$rname,$pos,$mapq,$cigar,$rnext,$pnext,$tlen,$seq) = split /\t/; 
    $read_sizes{length($seq)}++;
    if ($read_sizes{length($seq)} >= 10){
      $read_size=length($seq);
      last;
    }
  }
  close READS;
  ($name) = $filename =~ m!/*([^/\.]+?)\.bam!;

  open HEADER, "samtools view -H $filename |";

  while(<HEADER>){
    if(/\@SQ\s+SN:(.+)\s+LN:(.+)/){;
      my($seq,$size) = ($1,$2);
      $sizes{$seq}=$size;
    }
  }
  close HEADER;

  open DEPTH, "samtools depth $filename |";

  $count=0;
  my($chr,$pos,$depth) = split ' ',<DEPTH>;
  my $last_chr = $chr;
  process_depth($chr,$pos,$depth);
  while(<DEPTH>){
    my($chr,$pos,$depth) = split;
    if($chr ne $last_chr){
      print_depth(\%cov,$last_chr);
      %cov=();
    }
    process_depth($chr,$pos,$depth);
    $last_chr=$chr;
    print STDERR "\r".commify($count) if $count % 10000 == 0;
  }
  print STDERR "\r";
}

sub process_depth{
  my($chr,$pos,$depth) = @_;
  if($pos >= $read_size and $pos < $sizes{$chr} - $read_size){
    $cov{$depth}++;
    $count++;
  }
}
sub print_depth{
  my ($cov,$chr) = @_;
  my $coverage=0;
  my @depths;
  for my $depth(keys %{ $cov }){
    push @depths, (($depth) x $cov->{$depth});
  }
  push @depths, (0) x ($sizes{$chr} - (2*$read_size) - @depths);
  print join("\t",$name,$chr,$sizes{$chr},'');
  if(not @depths){
    print join("\t", (0) x 5) unless @depths;
  } else {
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@depths);
    print join("\t",$stat->min, $stat->mean,$stat->median,$stat->max, 
      $stat->standard_deviation);
  }
  print "\n";
}
sub commify {
  local $_  = shift;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

avg_coverage.pl - gets the average coverage per sequence from a bam file

=head1 SYNOPSIS

avg_coverage.pl [options] [file ...]

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

B<avg_coverage.pl> gets the average coverage per sequence from a bam file

=cut

