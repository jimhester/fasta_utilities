#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:01/14/2010
# Title:convertBowToFasta.pl
# Purpose:converts bowtie reads to fasta format
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
# convertBowToFasta.pl
###############################################################################
sub wrapLines($$);
sub printFasta($$);

while(<>){
  my($name, $strand, $target, $location, $sequence) = split /\t/;
  printFasta($name,$sequnece);
}
sub printFasta($$){
  print ">$_[0]\n";
  print wrapLines($_[1], 80);
}
sub wrapLines($$){
  my($line,$num) = @_;
  my $curr = 0;
  my $out;
  while($curr < length($line)){
    $out .= substr($line,$curr,$num) . "\n";
    $curr+=$num;
  }
  return $out;
}


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

convertBowToFasta.pl - converts bowtie reads to fasta format

=head1 SYNOPSIS

convertBowToFasta.pl [options] [file ...]

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

B<convertBowToFasta.pl> converts bowtie reads to fasta format

=cut

