#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/21/2011
# Title:pairs_unsorted.pl
# Purpose:this script gets the pairs of the files in the first file from the second file, pairs are matched by header name
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
# pairs_unsorted.pl
###############################################################################

my %headers;

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;
my $fastx1 = ReadFastx->new(shift);
while(my $seq = $fastx1->next_seq){
  if($seq->header =~ /^(.+?)(\/[12])|\n/){
    my ($header) = $1;
    $headers{$header}++;
  }
}
my $bar = JimBar->new();
my $fastx2 = ReadFastx->new(shift);
while(my $seq = $fastx2->next_seq){
  if($seq->header =~ /^(.+?)(\/[12])|\n/){
    my($header) = $1;
    if(exists $headers{$header}){
      $seq->print();
    }
  }
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

pairs_unsorted.pl - this script gets the pairs of the files in the first file from the second file, pairs are matched by header name

=head1 SYNOPSIS

pairs_unsorted.pl [options] [file ...]

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

B<pairs_unsorted.pl> this script gets the pairs of the files in the first file from the second file, pairs are matched by header name

=cut

