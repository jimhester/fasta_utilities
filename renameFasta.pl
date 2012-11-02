#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:06/24/2011
# Title:renameFasta.pl
# Purpose:renames fasta files from ncbi into uscs nomeclature chr##
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $prepend;
my $firstOnly;
my $short;
GetOptions('firstOnly' => \$firstOnly,'prepend=s' => \$prepend, 'short' => \$short, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# renameFasta.pl
###############################################################################

use readFastx;

my $file = readFastx->new();
while(my $seq = $file->next_seq){
    my $newHeader = $seq->header;
    ($newHeader) = split ' ',$newHeader if $firstOnly;
    if($short) {
      if($seq->header =~ /^([0-9XYM]+)\b/){
	$newHeader = "chr$1";
      } elsif($seq->header =~ /chr.*?\b([0-9XYM]+)\b/){
	$newHeader = "chr$1";
      } elsif($seq->header =~ /mitoch/){
	$newHeader = "chrM";
      } elsif($seq->header =~ /[\b_]([0-9]{1,2})\b/){
	$newHeader = "chr$1";
      }
      $newHeader =~ s/r0/r/; #remove leading 0
    }
    if($prepend){
      $newHeader = $prepend . $newHeader;
    }
    print STDERR "$seq->header\t$newHeader\n";
    $seq->header = $newHeader;
    $seq->print;
  }
}
#local $/ = ">";
#my $first = <>;
#while(<>){
#  if(/(.+?)\n(.+)\n/s){
#    my($header, $sequence) = ($1,$2);
#    my $newHeader = $header;
#    ($newHeader) = split ' ',$newHeader if $firstOnly;
#    if($short) {
#      if($header =~ /^([0-9XYM]+)\b/){
#	$newHeader = "chr$1";
#      } elsif($header =~ /chr.*?\b([0-9XYM]+)\b/){
#	$newHeader = "chr$1";
#      } elsif($header =~ /mitoch/){
#	$newHeader = "chrM";
#      } elsif($header =~ /[\b_]([0-9]{1,2})\b/){
#	$newHeader = "chr$1";
#      }
#      $newHeader =~ s/r0/r/; #remove leading 0
#    }
#    if($prepend){
#      $newHeader = $prepend . $newHeader;
#    }
#    print STDERR "$header\t$newHeader\n";
#    print ">$newHeader\n$sequence\n";
#  }
#}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

renameFasta.pl - renames fasta files from ncbi into uscs nomeclature chr##

=head1 SYNOPSIS

renameFasta.pl [options] [file ...]

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

B<renameFasta.pl> renames fasta files from ncbi into uscs nomeclature chr##

=cut

