#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/18/2011
# Title:merge_records.pl
# Purpose:merges all the input records into one record, by defualt uses the name of the first record, but can be changed with -name
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $name;
my $width = 80;
GetOptions('width' => \$width, 'name=s' => \$name, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# merge_records.pl
###############################################################################

use ReadFastx;

my $full_sequence;

my $file = ReadFastx->new();

while(my $seq = $file->next_seq){
  $full_sequence .= $seq->sequence;
  $name = $seq->header unless $name;
}

my $full = ReadFastx::Fasta->new(header => $name, sequence => $full_sequence);
$full->print;

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

merge_records.pl - merges all the input records into one record, by defualt uses the name of the first record, but can be changed with -name

=head1 SYNOPSIS

merge_records.pl [options] [file ...]

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

B<merge_records.pl> merges all the input records into one record, by defualt uses the name of the first record, but can be changed with -name

=cut

