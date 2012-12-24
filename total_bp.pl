#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/04/2009
# Title:total_bp.pl
# Purpose:this script calculates the total number of bases in a file
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
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# total_bp.pl
###############################################################################

use ReadFastx;
my $fastx = ReadFastx->new();
my $count = 0;
while(my $seq = $fastx->next_seq){
  $count+=length($seq->sequence);
}

print $count,"\n";

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

total_bp.pl - this script calculates the total number of bases in a file

=head1 SYNOPSIS

total_bp.pl [options] [file ...]

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

B<total_bp.pl> this script calculates the total number of bases in a file

=cut

