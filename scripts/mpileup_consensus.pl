#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# Title:mpileup_consensus.pl
# Created: 2012 Oct 26 08:28:19 AM
# Modified: 2013 Jan 25 03:57:07 PM
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
# mpileup_consensus.pl
###############################################################################

#setup and print headers
my @bases = qw(A C G T N);
print join("\t","chromosome","position","coverage","raf","reference",@bases)."\n";

my %sequences;
while(<>){
  #parse mpileup
  my($chr,$pos,$ref,$coverage,$reads,$qualities) = split;
  $sequences{$chr}{last} = 0 unless exists $sequences{$chr}; # initialize last position
  $reads = uc $reads; #make all letters uppercase
  $reads =~ s/[.,]/$ref/g; #change ref bases to ref letter
  $reads =~ s/\^.//g; #remove read starts and mapping quality
  $reads =~ s/\$//g; #remove read ends
  $reads =~ s/[\+\-]([0-9]+)(??{"\\w{$^N}"})//g; #remove indels

  #print base counts and raf
  my %counts;
  for my $base(@bases){
    my $count = $reads =~ s/$base/$base/g;
    $counts{$base} = $count ? $count : 0;
  }
  $sequences{$chr}{sequence} .= 'n' x $pos - ($sequences{$chr}{last} + 1); #pad with n's if nesseseary

  my $consensus_base = $counts{most_frequent_base(\%counts)};
  $sequences{$chr}{sequence} .= $consensus_base;
  $sequences{$chr}{last} = $pos;
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

mpileup_consensus.pl - parses a mpileup file and gets the basecounts

=head1 SYNOPSIS

mpileup_consensus.pl [options] [file ...]

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

B<mpileup_consensus.pl> parses a mpileup file and gets the basecounts

=cut

