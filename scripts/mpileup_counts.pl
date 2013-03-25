#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# Title:mpileup_counts.pl
# Created: 2012 Oct 26 08:28:19 AM
# Modified: 2013 Mar 25 02:16:11 PM
# Purpose:parses a mpileup file and gets the basecounts
# By Jim Hester
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
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# mpileup_counts.pl
###############################################################################
use Carp;

#setup and print headers
my @bases = qw(A C G T N);
print join("\t","chromosome","position","coverage","reference","raf",@bases)."\n";

my %sequences;
while(<>){
  #parse mpileup
  my($chr,$pos,$ref,$coverage,$reads,$qualities) = split;
  $sequences{$chr}{last} = 0 unless exists $sequences{$chr}; # initialize last position
  $reads = uc $reads; #make all letters uppercase
  $reads =~ s/[.,]/$ref/g; #change ref bases to ref letter
  $reads =~ s/\^.//g; #remove read starts and mapping quality
  $reads =~ s/\$//g; #remove read ends
  my $deleted = $reads =~ s/[*]//g;
  $reads =~ s/[\+\-]([0-9]+)(??{"\\w{$^N}"})//g; #remove indels

  #get counts for bases
  my %counts;
  my $total;
  for my $base(@bases){
    my $count = $reads =~ s/$base/$base/g || 0;
    $counts{$base}= $count ? $count : 0;
    $total+=$count;
  }
  croak "$total is not equal to $coverage\n" if $total != $coverage - $deleted;
  #print data
  print join("\t", $chr, $pos, $coverage, $ref,sprintf("%2f", $counts{$ref}/$coverage), map { $counts{$_} } @bases), "\n";
}

open my $out, "| ~/fu/wrap.pl" or die "$!: Could not open file\n";
for my $name (keys %sequences){
  print $out ">$name\n$sequences{$name}\n";
}
sub most_frequent_base{
  my($hash_ref) = @_;
  return (sort { $hash_ref->{$b} <=> $hash_ref->{$a} } keys %{ $hash_ref })[0];
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

mpileup_counts.pl - parses a mpileup file and gets the basecounts

=head1 SYNOPSIS

mpileup_counts.pl [options] [file ...]

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

B<mpileup_counts.pl> parses a mpileup file and gets the basecounts

=cut

