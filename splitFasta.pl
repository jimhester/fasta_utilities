#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/19/2009
# Title:splitFasta.pl
# Purpose:this script splits a genome into fragments of a given size
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $bpAmount = 10;
my $stepAmount;
my $onlyFull;
GetOptions('onlyFull' => \$onlyFull, 'size=i' => \$bpAmount, 'step=i' => \$stepAmount, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# splitFasta.pl
###############################################################################

if(not $stepAmount or $stepAmount > $bpAmount){
  $stepAmount = $bpAmount;
}

local $/=\1;
my $firstChar =<>;
if($firstChar eq ">"){
  doFasta();
} 
elsif($firstChar eq "@"){
  doFastq();
}
else{
  die "not a fasta or fastq file";
}

sub doFastq{
  local $/ = "@";
  while(<>){
    chomp;
    if(/^(.*?)\n(.*?)\n\+.*?\n(.*?)\n$/s){
      my($header, $sequence, $quality) = ($1,$2,$3);
      ($header) = split ' ', $header;
      $sequence =~ tr/\n//d;
      my $currStep = 0;
      while($currStep < length($sequence)-$bpAmount){
	my $fragment = substr($sequence, $currStep, $bpAmount);
	my $qualFrag = substr($quality, $currStep,$bpAmount);
	my $newHeader = "$header;$currStep-" . ($currStep+$bpAmount) . ";";
	print "<$newHeader\n$fragment\n+$newHeader\n$qualFrag\n";
	$currStep += $stepAmount;
      }
      if(not $onlyFull and $currStep != length($sequence)){
	my $fragment = substr($sequence, $currStep, length($sequence)-$currStep);
	my $qualFrag = substr($quality, $currStep,length($sequence)-$currStep);
	my $newHeader = "$header;$currStep-" .length($sequence) . ";";
	print "<$newHeader\n$fragment\n+$newHeader\n$qualFrag\n";
      }
    }
  }
}

sub doFasta{
  local $/ = ">";
  while(<>){
    chomp;
    if(/^(.*?)\n(.*)$/s){
      my ($header, $sequence) = ($1,$2);
      ($header) = split ' ', $header;
      $sequence =~ tr/\n//d;
      my $currStep = 0;
      while($currStep < length($sequence)-$bpAmount){
	my $fragment = substr($sequence, $currStep, $bpAmount);
	print ">$header;$currStep-" . ($currStep+$bpAmount) . ";\n$fragment\n";
	$currStep += $stepAmount;
      }
      if(not $onlyFull and $currStep != length($sequence)){
	my $fragment = substr($sequence, $currStep, length($sequence)-$currStep);
	print ">$header;$currStep-" . length($sequence) . ";\n$fragment\n";
      }
    }
  }
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

splitFasta.pl - this script splits a genome into fragments of a given size

=head1 SYNOPSIS

splitFasta.pl [options] [file ...]

Options:
      -size
      -step
      -onlyFull
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-size>

Set the size to split into

=item B<-step>

Set the step amount to use, default is size (non-overlapping)

=item B<-onlyFull>

Only output Sequences that are the correct size, if this is not set, at the end of the records a shorter fragment will be outputted

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<splitGenomoe.pl> this script splits a genome into fragments of a given size

=cut

