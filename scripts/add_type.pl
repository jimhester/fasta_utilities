#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 Apr 25 02:33:50 PM
# Last Modified: 2013 Jul 22 12:43:53 PM
# Title:add_type.pl
# Purpose:Add a type field to output
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my %args = (position=>-1, split => '\s+', out => "\t");
GetOptions(\%args, 'position=i', 'split=s', 'out=s', 'header', 'help|?', 'man')
or pod2usage(2); pod2usage(2) if exists $args{help};
pod2usage(-verbose => 2) if exists $args{man};
pod2usage("$0: No type given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# add_type.pl
###############################################################################

use Carp;

$args{split} = qr/$args{split}/;

my $type = shift;

if(exists $args{header}){
  print add_type(scalar <>, 'type');
}
while(<>){
  print add_type($_, $type);
}

sub add_type {
  my($line, $add) = @_;
  chomp $line;

  if($args{position} == 0){
    return $add . $args{out} . $line . $/;
  }
  elsif($args{position} < 0){
    return  $line . $args{out} . $add . $/;
  }
  my @records = split $args{split}, $line;
  croak "position: $args{position} is greater than the record size: ", scalar @records unless $args{position} <= @records;
  return join($args{out}, @records[0..$args{position}-1], $add, @records[$args{position}..$#{records}]) . $/;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

add_type.pl - Add a type field to output

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

B<add_type.pl> Add a type field to output

=cut

