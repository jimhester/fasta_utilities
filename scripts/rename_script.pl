#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2012 Dec 24 10:42:29 AM
# Last Modified: 2013 Feb 01 03:14:51 PM
# Title:rename_script.pl
# Purpose:Rename a file, changing any references to the old name in the file to
# the new name
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $git;
my $force;
my $delete;
GetOptions( 'git'    => \$git,
            'delete' => \$delete,
            'force'  => \$force,
            'help|?' => \$help,
            man      => \$man )
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
# rename_script.pl
###############################################################################

my $old_filename = shift;
open my $in, "<", "$old_filename" or die "$!:Could not open $old_filename\n";

my $new_filename = shift;
die "$new_filename exists, use --force to overwrite"
  if -e $new_filename and not $force;
open my $out, ">", "$new_filename" or die "$!:Could not open $new_filename\n";

my $old = no_extension( base($old_filename) );
my $new = no_extension( base($new_filename) );

while (<$in>) {
  s/$old/$new/g;
  print $out $_;
}
close $out;
system("chmod ug+x $new_filename");
unlink $old_filename if $delete;
exit;

sub base {
  my ($path) = @_;
  $path =~ s{.*/}{};
  return $path;
}

sub no_extension {
  my ($path) = @_;
  $path =~ s{\..*}{};
  return $path;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

rename_script.pl - Rename a file, changing any references to the old name in the file to the new name

=head1 SYNOPSIS

rename_script.pl [options] [file ...]

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

B<rename_script.pl> Rename a file, changing any references to the old name in the file to 
# the new name

=cut

