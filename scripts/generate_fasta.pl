#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 07 11:13:26 AM
# Last Modified: 2013 Jan 10 11:00:06 AM
# Title:generate_fasta.pl
# Purpose:randomly generate a fasta file
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $start = '';
my $length = 50;
my $number=100;
GetOptions('number=i' => \$number,
           'start=s'  => \$start,
           'length=i' => \$length,
           'help|?'   => \$help,
           man        => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
#pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# generate_fasta.pl
###############################################################################

generate_fasta($start,$length,$number);
exit;

sub generate_fasta{
  my($start,$length,$number, $fh) = @_;
  $fh = \*STDOUT unless $fh;
  for my $count(1..$number){
    my $header = ">$count";
    print $fh $header, "\n", "$start", rand_seq($length-length($start)), "\n";
  }
}
sub rand_seq{
  my ($length, $alphabet) = @_;
  $alphabet = [ qw(A C G T) ] unless $alphabet;
  my $out;
  for(1..$length){
    $out .= $alphabet->[rand(@{ $alphabet })];
  }
  return $out;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

generate_fasta.pl - randomly generate a fasta/q file

=head1 SYNOPSIS

generate_fasta.pl [options] [file ...]

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

B<generate_fasta.pl> randomly generate a fasta/q file

=cut

