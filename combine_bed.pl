#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2012 Dec 13 03:49:14 PM
# Last Modified: 2012 Dec 14 11:25:18 AM
# Title:combine_bed.pl
# Purpose:Combine bed files
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my @header_names;
my $missing = "NA";
my $no_headers;
my $percent_missing = 100;
my $simplify;
GetOptions('headers=s'         => \@header_names,
           'missing=s'         => \$missing,
           'no_headers'        => \$no_headers,
           'percent_missing=f' => \$percent_missing,
           'simplify=s'        => \$simplify,
           'help|?'            => \$help,
           man                 => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));

for my $header_name (@header_names) {
  $header_name = [split /,/, $header_name];
}
###############################################################################
# combine_bed.pl
###############################################################################
#used to test if any of the values in an array meet a condition
use List::MoreUtils qw(any);

#used to create writable aliases
use Data::Alias;

# Automatically extract compressed files, cat to stdout if not compressed
my @files = map { unzip_or_cat($_) } @ARGV;

#open filehandles and sort with gnu sort before reading
my @fhs = map { open_sorted_bed($_); } @files;

#initialize @lines with the first lines of all the files
my @lines = map { read_line($_); } @fhs;

#get the width of the data by counting the tabs
my @data_widths = map { $_->{data} =~ tr/\t/\t/ } @lines;

print_headers(\@ARGV, \@data_widths) unless $no_headers;

#get the lowest line from the first lines
my ($lowest) = lowest(\@lines);

#calculate the number of records which must be missing to be above the percent 
#missing threshold
my $missing_cutoff = int($percent_missing / 100 * @fhs);

#while there is still data
while (any { defined($_) } @lines) {

  #print the chromosome and position for current line
  my $line_out = $lowest->{chromosome} . "\t" . $lowest->{position};
  my $num_missing = 0;
  for my $itr (0 .. $#fhs) {
    alias my $line = $lines[$itr];
    alias my $fh   = $fhs[$itr];
    my $cmp = bed_cmp($line, $lowest);

    #if the current file has the current lowest line, print data, get next line
    #for fh
    if (defined($cmp) and $cmp == 0) {
      $line_out .= $line->{data};
      $line = read_line($fh);
    }

    #else data is missing, so print missing data for the width of the data
    else {
      $line_out .= ("\t$missing") x $data_widths[$itr];
      $num_missing++;
    }
  }
  print $line_out, "\n" unless ($num_missing > $missing_cutoff);

  #get the new lowest line
  ($lowest) = lowest(\@lines);
}
exit;

#if file name is .gz or .bz unzip, otherwise just cat
sub unzip_or_cat {
  my ($file_name) = @_;
  unless ($file_name =~ s/(.*\.gz)\s*$/pigz -dc < $1|/ or $file_name =~ s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/) {
    $file_name = "cat $file_name |";
  }
  return $file_name;
}

#open and sort bed files
sub open_sorted_bed {
  my ($file_name) = @_;
  open my $fh, "$file_name sort -k1,1 -k2,2n|"
    or die "$!:Could not open $file_name";
  return $fh;
}

#print the headers
sub print_headers {
  my ($files, $data_widths) = @_;
  my $itr = 0;
  print "chromosome\tposition";
  for my $itr (0 .. $#{$files}) {
    my $file = $files->[$itr];
    eval "\$file =~ $simplify" if ($simplify);
    warn $@ if $@;
    my $headers;
    if (@header_names) {

      #use modulo header names to recycle the names
      $headers = $header_names[$itr % @header_names];
      my $num_data   = $data_widths->[$itr];
      my $num_header = @{$headers};
      die "$file has $num_data data columns, but only $num_header header columns supplied\n" if $num_data > $num_header;
    }
    else {
      $headers = [0 .. ($data_widths->[$itr] - 1)];
    }
    print map {"\t${file}_$_"} @{$headers};
    $itr++;
  }
  print "\n";
}

#read and parse a line from a file handle
sub read_line {
  my ($fh) = @_;
  my $line = <$fh>;
  return unless $line;
  chomp $line;
  my ($chr, $pos, $rest) = $line =~ m{([^\t]+)\t([^\t]+)(.*)};
  return ({data => $rest, chromosome => $chr, position => $pos});
}

#get the lowest of the lines
sub lowest {
  my $lines = shift;
  my $lowest;
  for my $line (@{$lines}) {
    if (defined $line) {
      my ($chr, $pos) = split /\t/, $line;
      if (not defined $lowest or bed_cmp($line, $lowest) == -1) {
        $lowest = $line;
      }
    }
  }
  return ($lowest);
}

#compare two lines based on their chromosome, the position
sub bed_cmp {
  my ($first, $second) = @_;
  return if any { not defined($_) } ($first, $second);
  return $first->{chromosome} cmp $second->{chromosome}
    || $first->{position} <=> $second->{position};
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

combine_bed.pl - Combine bed files

=head1 SYNOPSIS

combine_bed.pl [options] [file ...]

Options:
      -headers 
      -missing
      -no_headers
      -percent_missing
      -simplify
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-headers> <>

Names to give the headers, they are recycled if needed, default headers are 0 to the number of rows

=item B<-missing> <NA>

Value used for missing data, NA by default

=item B<-no_headers>

Do not print headers

=item B<-percent_missing> <100.0>

Percentage of missing data allowed, e.g. if 50 lines which have more than 50% missing data will not be printed

=item B<-simplify> <>

Substitution regular expression used to simplify the headers

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<combine_bed.pl> Combine bed files

=cut

