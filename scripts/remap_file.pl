#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:01/24/2012
# Title:remap_file.pl
# Purpose:takes a file with tab deliminated mappings and substitutes each of the first terms for each of the second terms
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $split = '\s+';
my $global;
my $first;
GetOptions('first' => \$first, 'split=s' => \$split, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# remap_file.pl
###############################################################################

my $mappingFile = shift;

open MAP, $mappingFile or die "$!: Could not open $mappingFile";
my %map;
while(<MAP>){
  chomp;
  my ($first,$second) = split /$split/;
  $map{$first}=$second;
}

while(<>){
  my $found;
  if($first){
    $found = s/^(\S+)/ exists $map{$1} ? $map{$1} : $1/e;
  }
  unless($found){
    while(my ($old,$new) = each %map){
      if($first){
        s/^\Q$old\E/$new/;
      }else{
      s/\Q$old\E/$new/g;
      }
    }
  }
  print;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

remap_file.pl - takes a file with tab deliminated mappings and substitutes each of the first terms for each of the second terms

=head1 SYNOPSIS

remap_file.pl [options] [file ...]

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

B<remap_file.pl> takes a file with tab deliminated mappings and substitutes each of the first terms for each of the second terms

=cut

