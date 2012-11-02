#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/30/2011
# Title:removeAmbiguity.pl
# Purpose:removes ambiguity codes from fasta files
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $toN;
GetOptions('N' => \$toN,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# removeAmbiguity.pl
###############################################################################

use readFastx;

my %mapping = ( '[MRWVHDN]' => 'A','[YKB]' => 'T', S => 'C' );

%mapping = ( '[MRWVHDYKBS]' => 'N') if $toN;

my $file = readFastx->new();

while(my $seq = $file->next_seq){
  for my $map(keys %mapping){
    $seq->sequence =~ s/$map/$mapping{$map}/gi;
  }
  $seq->print(undef,80);
}
#local $/ = ">";
#
#my $first = <>;
#while(<>){
#  chomp;
#  my $newline = index($_,"\n");
#  my $header = substr($_,0,$newline);
#  my $sequence = substr($_,$newline+1);
#  for my $map(keys %mapping){
#    $sequence =~ s/$map/$mapping{$map}/gi;
#  }
#  print ">$header\n$sequence";
#}
#



###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

removeAmbiguity.pl - removes ambiguity codes from fasta files

=head1 SYNOPSIS

removeAmbiguity.pl [options] [file ...]

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-N>

convert each ambiguous mapping to an N

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<removeAmbiguity.pl> removes ambiguity codes from fasta files

=cut

