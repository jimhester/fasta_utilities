#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/13/2010
# Title:convertToBigFormat.pl
# Purpose:this script takes a bed, sam, or wiggle file and creates a big version of it to upload to ucsc
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $prefix;
GetOptions('prefix=s' => \$prefix,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: Please give a file to convert and the chromosome sizes file for your reference genome")  if ((@ARGV != 2) && (-t STDIN));
###############################################################################
# convertToBigFormat.pl
###############################################################################

my $filename = shift;
my $sizesFile = shift;

if($filename =~ /(.*)\.sam/){
  $prefix = $1 if not $prefix;
  doSam($prefix);
}
if($filename =~ /(.*)\.bed/){
  $prefix = $1 if not $prefix;
  doBed($prefix);
}
if($filename =~ /(.*)\.wig/){
  $prefix = $1 if not $prefix;
  doWig($prefix);
}

sub doSam{
  my($prefix) = shift;
  system("samtools view -t $sizesFile -S -b $filename | samtools sort - $prefix");
  system("samtools index $prefix.bam");
}
sub doBed{
  my($prefix) = shift;
  system("tail -n +2 $filename | sort -k1,1 -k2,2n > .temp");
  system("bedToBigBed .temp $sizesFile $prefix.bb");
  system("rm .temp");
}
sub doWig{
  my($prefix) = shift;
  system("tail -n +2 $filename > .temp");
  system("wigToBigWig .temp $sizesFile $prefix.bw");
  system("rm .temp");
}


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

convertToBigFormat.pl - this script takes a bed, sam, or wiggle file and creates a big version of it to upload to ucsc

=head1 SYNOPSIS

convertToBigFormat.pl [options] [file ...]

Options:
      -prefix
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-prefix>

set the prefix you want the file to have, by default it is the same prefix as the input file

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<convertToBigFormat.pl> this script takes a bed, sam, or wiggle file and creates a big version of it to upload to ucsc

=cut

