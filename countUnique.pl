#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:07/20/2010
# Title:countUnique.pl
# Purpose:Counts the number of unique reads and total reads, also can print the unique reads if given the -p switch
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $print;
GetOptions('print|p' => \$print, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# countUnique.pl
###############################################################################
use JimBar;
my $bar = JimBar->new();
my $uniqueCount = 0;
while(<>){
  if(/\s0\s([0-9\>\:A-Z],*)*$|X0:i:1/){ #first is for bowtie files, second is for sam
    print $_ if($print);
    $uniqueCount++;
  }
}
$bar->done();
print STDERR "$uniqueCount\t$.\n";


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

countUnique.pl - Counts the number of unique reads and total reads, also can print the unique reads if given the -p switch

=head1 SYNOPSIS

countUnique.pl [options] [file ...]

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

B<countUnique.pl> Counts the number of unique reads and total reads, also can print the unique reads if given the -p switch

=cut

