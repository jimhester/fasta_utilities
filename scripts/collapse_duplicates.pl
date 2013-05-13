#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 May 13 11:56:06 AM
# Last Modified: 2013 May 13 02:26:15 PM
# Title:collapse_duplicates.pl
# Purpose:Collapse duplicate reads, keeping reads counts
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my %args = ();
GetOptions(\%args, 'paired', 'help|?', 'man') or pod2usage(2);
pod2usage(2) if exists $args{help};
pod2usage(-verbose => 2) if exists $args{man};
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# collapse_duplicates.pl
###############################################################################

if(exists $args{paired}){
  paired();
}
else {
  single();
}

sub single{
  open my $fh, "sort.pl --sequence @ARGV |";

  use ReadFastx;
  my $fastx = ReadFastx->new(fh => $fh);
  my $prev = $fastx->next_seq;
  my $count = 1;
  while(my $seq = $fastx->next_seq){
    if($prev->sequence ne $seq->sequence){
      $prev->header($prev->header . ":$count");
      $prev->print();
      $count=0;
    }
    $prev=$seq;
    $count++;
  }
  $prev->header($prev->header . ":$count");
  $prev->print();
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

collapse_duplicates.pl - Collapse duplicate reads, keeping reads counts

=head1 VERSION

0.0.1

=head1 USAGE

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<collapse_duplicates.pl> Collapse duplicate reads, keeping reads counts

=cut

