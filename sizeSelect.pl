#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:12/14/2010
# Title:sizeSelect.pl
# Purpose:returns the sequences with lengths between the values specified by -low and -high
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $low = 0;
my $high = 10000000000000000;
GetOptions('low=i' => \$low, 'high=i' => \$high, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# sizeSelect.pl
###############################################################################

local $/=\1;
my $firstChar =<>;
use JimBar;
my $bar = JimBar->new();
if($firstChar eq ">"){
  procFasta();
} 
elsif($firstChar eq "@"){
  procFastq();
}
else{
  die "not a fasta or fastq file";
}
$bar->done;
sub procFasta{
  local $/ = ">";
  while(<>){
    chomp;
    if(/^(.*?)\n(.*)$/s){
      my ($title, $sequence) = ($1,$2);
      $sequence =~ tr/\n//d;
      if(length($sequence) >= $low and length($sequence) <= $high){
	print ">$title\n$sequence\n";
      }
    }
  }
}
sub procFastq{
  local $/ = "@";
  while(<>){
    chomp;
    if(/^(.*?)\n(.*?)\n\+.*?\n(.*?)\n$/s){
      my ($title, $sequence,$quality) = ($1,$2,$3);
      $sequence =~ tr/\n//d;
      if(length($sequence) >= $low and length($sequence) <= $high){
	print "\@$title\n$sequence\n\+$title\n$quality\n";
      }
    }
  }
}



###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

sizeSelect.pl - returns the sequences with lengths between the values specified by -low and -high

=head1 SYNOPSIS

sizeSelect.pl [options] [file ...]

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

B<sizeSelect.pl> returns the sequences with lengths between the values specified by -low and -high

=cut

