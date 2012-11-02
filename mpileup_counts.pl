#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# Title:mpileup_counts.pl
# Created: 2012 Oct 26 08:28:19 AM
# Modified: 2012 Oct 26 10:59:47 AM
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

#setup and print headers
my @bases = qw(A C G T N);
print join("\t","chromosome","position","coverage","raf","reference",@bases)."\n";

while(<>){
  #parse mpileup
  my($chr,$pos,$ref,$coverage,$reads,$qualities) = split;
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
  print join("\t",$chr, $pos, $coverage, sprintf("%6.2f",$counts{$ref}/$coverage*100)
    ,$ref,(map { $counts{$_} } @bases))."\n";
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

