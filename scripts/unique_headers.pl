#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/17/2011
# Title:unique_headers.pl
# Purpose:this script reads a fastafile and ensures all of the names are unique
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
GetOptions('help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# unique_headers.pl
###############################################################################

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;

my $fastx = ReadFastx->new();

my %names = ();
while(my $seq = $fastx->next_seq){
  my($header) = split ' ',$seq->header;
  while(exists $names{$header}){
    if($header =~ /(.+)\.([0-9]+)$/){
      $header = $1.($2+1);
    } else {
      $header .= ".1";
    }
  }
  $names{$header}++;
  $seq->header($header);
  $seq->print;
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

unique_headers.pl - this script reads a fastafile and ensures all of the names are unique

=head1 SYNOPSIS

unique_headers.pl [options] [file ...]

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

B<unique_headers.pl> this script reads a fastafile and ensures all of the names are unique

=cut

