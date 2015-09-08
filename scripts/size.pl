#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 14 01:15:46 PM
# Last Modified: 2013 Apr 11 01:29:42 PM
# Title:size.pl
# Purpose:Get number of sequences and total size
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
GetOptions( 'help|?' => \$help, man => \$man ) or pod2usage(2);
pod2usage(2) if $help;
pod2usage( -verbose => 2 ) if $man;
pod2usage("$0: No files given.") if ( ( @ARGV == 0 ) && ( -t STDIN ) );
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map {
  s/(.*\.gz)\s*$/pigz -dc < $1|/;
  s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;
  $_
} @ARGV;
###############################################################################
# size.pl
###############################################################################
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

my ( $total_size, $total_num ) = ( 0, 0 );

my $fastx = ReadFastx->new();

my $prev_filename = $fastx->current_file;
my ( $current_size, $current_num ) = ( 0, 0 );
while ( my $seq = $fastx->next_seq ) {
  if ( $prev_filename ne $fastx->current_file ) {
    print join( "\t", $prev_filename, $current_num, $current_size ), "\n";
    $total_size += $current_size;
    $total_num += $current_num;
    ( $current_size, $current_num ) = ( 0, 0 );
    $prev_filename = $fastx->current_file();
  }
  $current_size += length( $seq->sequence );
  $current_num++;
}
print join( "\t", $prev_filename, $current_num, $current_size ), "\n";
print join( "\t", 'total', $total_num, $total_size ), "\n" if $total_num;
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

size.pl - Get number of sequences and total size

=head1 SYNOPSIS

size.pl [options] [file ...]

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

B<size.pl> Get number of sequences and total size

=cut

