#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:08/24/2009
# Title:fastaLengths.pl
# Purpose:
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $cuttoff = 0;
GetOptions('cutoff|c=i' => \$cuttoff, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# fastaLengths.pl
###############################################################################

@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;

use readFastx;

my $fastx = readFastx->new();

while(my $seq = $fastx->next_seq){
  print $seq->header . "\t" . length($seq->sequence) . "\n";
}
#local $/=\1;
#my $firstChar =<>;
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
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*)$/s){
#      my ($title, $sequence) = ($1,$2);
#      $sequence =~ tr/\n//d;
#      print "$title\t" . length($sequence) . "\n";
#    }
#  }
#}
#sub procFastq{
#  local $/ = "@";
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*?)\n\+.*?\n(.*?)\n$/s){
#      my ($title, $sequence) = ($1,$2);
#      $sequence =~ tr/\n//d;
#      print "$title\t" . length($sequence) . "\n";
#    }
#  }
#}


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

fastaLengths.pl - 

=head1 SYNOPSIS

fastaLengths.pl [options] [file ...]

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-cutoff>

Set the cutoff length to take sequences above

=back

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<fastaLengths.pl> 

=cut

