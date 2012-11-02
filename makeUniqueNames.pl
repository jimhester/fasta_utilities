#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/17/2011
# Title:makeUniqueNames.pl
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
# makeUniqueNames.pl
###############################################################################

use readFastx;

my $fastx = readFastx->new();

my %names = ();
while(my $seq = $fastx->next_seq){
  ($seq->header) = split ' ',$seq->header;
  while(exists $names{$seq->header}){
    if($seq->header =~ /(.+)\.([0-9]+)$/){
      $seq->header = $1.($2+1);
    } else {
      $seq->header .= ".1";
    }
  }
  $names{$seq->header}++;
  $seq->print;
}

#local $/ = ">";
#
#my %names = ();
#
#use JimBar;
#my $bar = JimBar->new();
#
#my $first = <>;
#while(<>){
#  chomp;
#  my $name = substr($_,0,index($_, "\n")-1);
#  ($name) = split ' ',$name;
#  while(exists $names{$name}){
#    if($name =~ /(.+)\.([0-9]+)$/){
#      $name = $1.($2+1);
#    } else {
#      $name .= ".1";
#    }
#  }
#  $names{$name}++;
#  print '>',$name,substr($_,index($_,"\n"));
#}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

makeUniqueNames.pl - this script reads a fastafile and ensures all of the names are unique

=head1 SYNOPSIS

makeUniqueNames.pl [options] [file ...]

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

B<makeUniqueNames.pl> this script reads a fastafile and ensures all of the names are unique

=cut

