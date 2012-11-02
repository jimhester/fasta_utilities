#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:12/02/2010
# Title:PSSMreads.pl
# Purpose:this script constructs a position specific scoring matrix for qualities based on a sam file, it differentiates qualities between matches and mismatches
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
# PSSMreads.pl
###############################################################################





###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

PSSMreads.pl - this script constructs a position specific scoring matrix for qualities based on a sam file, it differentiates qualities between matches and mismatches

=head1 SYNOPSIS

PSSMreads.pl [options] [file ...]

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

B<PSSMreads.pl> this script constructs a position specific scoring matrix for qualities based on a sam file, it differentiates qualities between matches and mismatches

=cut

