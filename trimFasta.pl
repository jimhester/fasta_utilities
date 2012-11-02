#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/15/2009
# Title:trimFasta.pl
# Purpose:
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $amount = 36;
my $startPos = 0;
my $random;

GetOptions('num|trim|amount|t|a|n=i' => \$amount,'start=i' => \$startPos, 
'random|r' => \$random,'help|?' => \$help, man => \$man) or pod2usage(2);

pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# trimFasta.pl
###############################################################################

use readFastx;

my $file = readFastx->new();

while(my $seq = $file->next_seq){
  if($random){
    $startPos = int(rand(length($seq->sequence)-$amount));
  }
  $seq->sequence = substr($seq->sequence,$startPos,$amount);
  if($seq->isa("readFastx::Fastq::Seq")){
    $seq->quality = substr($seq->quality,$startPos,$amount);
  }
  $seq->print;
}
#local $/=\1;
#my $firstChar =<>;
#my $startPos =0;
#if($firstChar eq ">"){
#  procFasta();
#} 
#elsif($firstChar eq "@"){
#  procFastq();
#}
#else{
#  die "not a fasta or fastq file";
#}
#sub procFasta{
#  local $/ = ">";
#  my $first = ">";
#  if(length($first) != 1){
#    die "incorrectly formatted fasta file";
#  }
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*)\n$/s){
#      my $header = $1;
#      my $sequence = $2;
#      $sequence =~ tr/\n//d;
#      if($random){
#	$startPos = int(rand(length($sequence)-$amount));
#      }
#      my $outSeq = substr($sequence, $startPos,$amount);
#      if($random){
#	while($outSeq =~ tr/N/N/ > 2){
#	  $startPos = int(rand(length($sequence)-$amount));
#	  $outSeq = substr($sequence, $startPos,$amount);
#	}
#      }
#      print ">$header\n$outSeq\n";
#    }
#  }
#}
#
#sub procFastq{
#  local $/ = "@";
#  my $first = "@";
#  if(length($first) != 1){
#    die "incorrectly formatted fastq file";
#  }
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*?)\n\+.*?\n(.*?)\n$/){
#      my($header, $sequence, $quality) = ($1,$2,$3);
#      $sequence =~ tr/\n//d;
#      $quality =~ tr/\n//d;
#      $startPos = rand(length($sequence)-$amount) if($random);
#      my $outSeq = substr($sequence, $startPos,$amount);
#      if($random){
#	while($outSeq =~ tr/N/N/ > 2){
#	  $startPos = rand(length($sequence)-$amount) if($random);
#	  $outSeq = substr($sequence, $startPos, $amount);
#	}
#      }
#      $quality = substr($quality, $startPos, $amount);
#      print "\@$header\n$outSeq\n+$header\n$quality\n";
#    }
#  }
#}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

trimFasta.pl - 

=head1 SYNOPSIS

trimFasta.pl [options] [file ...]

Options:
      -t,-n,-a,-trim,-num,-amount
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-t,-n,-a,-trim,-num,-amount>

Set the amount to trim

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<trimFasta.pl> 

=cut

