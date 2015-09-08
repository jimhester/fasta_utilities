#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:06/24/2011
# Title:standardize_names.pl
# Purpose:renames fasta files from ncbi into uscs nomeclature chr##
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $prepend;
my $firstOnly;
my $short;
GetOptions('firstOnly' => \$firstOnly, 'prepend=s' => \$prepend, 'short' => \$short, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/; $_ } @ARGV;
###############################################################################
# standardize_names.pl
###############################################################################

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;

my $file = ReadFastx->new();
while (my $seq = $file->next_seq) {
  my $new_header = $seq->header;
  ($new_header) = split ' ', $new_header if $firstOnly;
  if ($short) {
    if ($new_header =~ /^([0-9XYM]+)\b/) {
      $new_header = "chr$1";
    }
    elsif ($seq->header =~ /chr.*?\b([0-9XYM]+)\b/) {
      $new_header = "chr$1";
    }
    elsif ($seq->header =~ /mitoch/) {
      $new_header = "chrM";
    }
    elsif ($seq->header =~ /[\b_]([0-9]{1,2})\b/) {
      $new_header = "chr$1";
    }
    $new_header =~ s/chr0/chr/;    #remove leading 0
  }
  if ($prepend) {
    $new_header = $prepend . $new_header;
  }
  print STDERR "$seq->header\t$new_header\n";
  $seq->header($new_header);
  $seq->print;
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

standardize_names.pl - renames fasta files from ncbi into uscs nomeclature chr##

=head1 SYNOPSIS

standardize_names.pl [options] [file ...]

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

B<standardize_names.pl> renames fasta files from ncbi into uscs nomeclature chr##

=cut

