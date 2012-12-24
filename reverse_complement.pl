#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:07/07/2010
# Title:/home/hesterj/fastaUtilities/reverse_complement.pl
# Purpose:takes sequences and reverse complements them
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
# /home/hesterj/fastaUtilities/reverse_complement.pl
###############################################################################

use ReadFastx;

my $file = ReadFastx->new();

while(my $seq = $file->next_seq){
  $seq->sequence(reverse_complement($seq->sequence));
  $seq->print;
}
sub reverse_complement{
  my($in) = @_;
  $in =~ tr/ACGTacgt/TGCAtgca/;
  return(reverse($in));
}
###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

/home/hesterj/fastaUtilities/reverse_complement.pl - takes sequences and reverse complements them

=head1 SYNOPSIS

/home/hesterj/fastaUtilities/reverse_complement.pl [options] [file ...]

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

B</home/hesterj/fastaUtilities/reverse_complement.pl> takes sequences and reverse complements them

=cut

