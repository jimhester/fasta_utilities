#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/19/2009
# Title:/home/hesterj/fastaUtilities/removeNSequencesFasta.pl
# Purpose:this script outputs only those sequences which have fewer than -num N's, default 2
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $cutoff = 2;
GetOptions('cutoff|num=i' => \$cutoff, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# /home/hesterj/fastaUtilities/removeNSequencesFasta.pl
###############################################################################

local $/=\1;
my $firstChar =<>;
if($firstChar eq ">"){
  procFasta();
} 
elsif($firstChar eq "@"){
  procFastq();
}
else{
  die "not a fasta or fastq file";
}
sub procFasta{
  local $/ = ">";
  while(<>){
    chomp;
    if(/^(.*?)\n(.*)$/s){
      my ($title, $sequence) = ($1,$2);
      $sequence =~ tr/\n//d;
      my($Ncount) = $sequence =~ tr/[Nn]//;
      if($Ncount <= $cutoff){
	print ">$_";
      }
  }
}
}
sub procFastq{
  local $/ = "@";
  while(<>){
    chomp;
    if(/^(.*?)\n(.*?)\n\+.*?\n(.*?)\n$/s){
      my ($title, $sequence) = ($1,$2);
      my($Ncount) = $sequence =~ tr/[Nn]//;
      if($Ncount <= $cutoff){
	print ">$_";
      }
    }
  }
}



###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

/home/hesterj/fastaUtilities/removeNSequencesFasta.pl - this script outputs only those sequences which have fewer than -num N's, default 2

=head1 SYNOPSIS

/home/hesterj/fastaUtilities/removeNSequencesFasta.pl [options] [file ...]

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

B</home/hesterj/fastaUtilities/removeNSequencesFasta.pl> this script outputs only those sequences which have fewer than -num N's, default 2

=cut

