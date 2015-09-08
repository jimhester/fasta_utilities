#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:05/09/2012
# Title:in_list.pl
# Purpose:reads a list of headers, and a fastx file and outputs records which are in the list
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $inverse=0;
my @list;
my @files;
GetOptions('list=s' => \@list, 'files=s' => \@files, 'v' => \$inverse, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# in_list.pl
###############################################################################
use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;

@list = split(/,/,join(',',@list));
@files = split(/,/,join(',',@files));

my %headers;

for my $term(@list){
  $headers{$term}++;
}
push @files, shift if(not @list and not @files);

for my $file(@files){
  open LIST, $file or die "$!: Could not open $file\n";
  while(<LIST>){
    chomp;
    $headers{$_}++;
  }
}
print STDERR "number in list ".scalar(keys %headers)."\n";
my $fastx = ReadFastx->new();

my($total,$count) = (1,0);
while(my $seq = $fastx->next_seq){
  ($seq->header) = split /[\s\/]+/,$seq->header;
  my $found = exists $headers{$seq->header};
  if($found xor $inverse){
    $seq->print;
    $count++;
  }
 print STDERR "\r$ARGV: $total $count" if $total % 100000 == 0;
 $total++;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

in_list.pl - reads a list of headers, and a fastx file and outputs records which are in the list

=head1 SYNOPSIS

in_list.pl [options] [file ...]

Options:
      -files
      -list
      -v
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-files>

uses all of the (comma seperated) files as searches

=item B<-list>

does not parse any file, just uses the (comma seperated) terms

=item B<-v>

outputs records which do not match (inverse)

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<in_list.pl> reads a list of headers, and a fastx file and outputs records which are in the list

=cut

