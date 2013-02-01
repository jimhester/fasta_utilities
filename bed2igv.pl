#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 22 09:30:31 AM
# Last Modified: 2013 Jan 22 09:44:53 AM
# Title:bed2igv.pl
# Purpose:Converts a bed file to a igv snapshot script
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $use_name;
my $collapse;
my $session;
my $path = "./";
my $img="png";
GetOptions( 'name'      => \$use_name,
            'collapse'  => \$collapse,
            'session=s' => \$session,
            'path=s'    => \$path,
            'img=s'     => \$img,
            'help|?'    => \$help,
            man         => \$man )
  or pod2usage(2);
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
# bed2igv.pl
###############################################################################

print "snapshotDirectory $path\n";
print "load $session\n" if $session;

while(<>){
  chomp;
  my($chromosome, $start, $end, $name) = split /\t/;
  print "goto $chromosome:" . ($start+1) . "-$end\n";
  print "collapse\n" if $collapse;
  my $snap_filename = $use_name ? "$name.$img" : "$chromosome-$start-$end.$img";
  print "snapshot $snap_filename\n"
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

bed2igv.pl - Converts a bed file to a igv snapshot script

=head1 SYNOPSIS

bed2igv.pl [options] [file ...]

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

B<bed2igv.pl> Converts a bed file to a igv snapshot script

=cut

