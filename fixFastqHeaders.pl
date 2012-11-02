#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:12/02/2010
# Title:/home/hesterj/fastaUtilities/fixFastaHeaders.pl
# Purpose:this script fixes the fastqheader by removing spaces and optionally appending a suffix
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $suffix ='';
my $prefix = '';
GetOptions('prefix=s' => \$prefix, 'suffix=s' => \$suffix, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# /home/hesterj/fastaUtilities/fixFastqHeaders.pl
###############################################################################
use readFastx;
use JimBar;

my $fastx = readFastx->new();

while(my $seq = $fastx->next_seq()){
  $seq->header = join("|",$prefix, $seq->header, $suffix);
  $seq->header =~ tr/ /|/;
  $seq->header =~ tr/+//d;
  $seq->print;
}
##local $/ = \1;
#my $firstChar = <>;
#if($firstChar eq "@"){
#  $/ = "@";
#  my $first = <>;
#  my $bar = JimBar->new();
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*?)\n\+.*?\n(.*?)$/s){
#      my ($header, $sequence,$quality) = ($1,$2,$3);
#      $header =~ tr/ /|/;
#      $header =~ tr/+//d;
#      print "\@$header$suffix\n$sequence\n+$header$suffix\n$quality\n";
#    }
#    else{
#      print STDERR;
#    }
#  }
#  $bar->done();
#} elsif($firstChar eq ">") {
#  $/ = ">";
#  my $first = <>;
#  my $bar = JimBar->new();
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*?)$/s){
#      my ($header, $sequence) = ($1,$2);
#      $header =~ tr/ /|/;
#      $header =~ s/[\+\.\,\-]+/|/g;
#      print "\>$prefix$header$suffix\n$sequence\n";
#    }
#    else{
#      print STDERR;
#    }
#  }
#  $bar->done();
#} else {
#    die "$ARGV does not look like a fasta or fastq file\n";
#  }


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

/home/hesterj/fastaUtilities/fixFastqHeaders.pl - this script fixes the fastqheader by removing spaces and optionally appending a suffix

=head1 SYNOPSIS

/home/hesterj/fastaUtilities/fixFastqHeaders.pl [options] [file ...]

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

B</home/hesterj/fastaUtilities/fixFastqHeaders.pl> this script fixes the fastqheader by removing spaces and optionally appending a suffix

=cut

