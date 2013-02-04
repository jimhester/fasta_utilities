#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/01/2012
# Title:blast_information.pl
# Purpose:gets sequence information from gi numbers from a blast results file
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my @format;
my $database;
GetOptions('database=s' => \$database,'format=s' => \@format,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# blast_information.pl
###############################################################################
@format = split(/,/,join(",",@format));
@format = "%t" unless @format;

my %gis;
while(<>){
  if(not $database and /^# Database: (\S+)/){
    $database=$1;
  }
  s!gi\|([0-9]+)\S+!
    my $out;
    if(exists $gis{$1}){
      $out = $gis{$1};
    }
    else{
      open my $gi, "blastdbcmd -db $database -outfmt '". join("|",@format). "' -entry $1 |"; 
      $out = <$gi>;
      if($out){
        chomp $out;
        $out = join("\t",split(/\|/, $out));
      } else {
        $out = $1;
      }
      $gis{$1}=$out;
    }
  $out!e;
 print;
}



###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

blast_information.pl - gets sequence information from gi numbers from a blast results file

=head1 SYNOPSIS

blast_information.pl [options] [file ...]

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

B<blast_information.pl> gets sequence information from gi numbers from a blast results file

=cut

