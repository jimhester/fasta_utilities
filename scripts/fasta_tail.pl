#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 02 02:08:49 PM
# Last Modified: 2013 Jan 02 03:26:45 PM
# Title:fasta_tail.pl
# Purpose:tail of fastx formated files
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man        = 0;
my $help       = 0;
my $tail_start = .9;
my $size       = 10;
my $width;
GetOptions('width=i'      => \$width,
           'size|n=i'     => \$size,
           'tail_start=f' => \$tail_start,
           'help|?'       => \$help,
           man            => \$man)
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/; $_ } @ARGV;
###############################################################################
# fasta_tail.pl
###############################################################################

use Carp;

croak "tail_start must be between 0 and 1, is $tail_start" if $tail_start > 1 or $tail_start < 0;

my @bin;

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;
my $fastx = ReadFastx->new();
my $count;
my $seq = $fastx->next_seq;

#set to last file unless reading from stdin
$fastx->current_file($fastx->files->[-1]) unless $fastx->files->[-1] eq "-";

if (seekable($fastx->files)) {
  my $file_size = -s $fastx->current_file;
  file_seek($fastx, int($file_size * $tail_start));
  $count = read_records($fastx);
  while ($count < $size and $tail_start > 0) {

    # try last .1 .2 .4 .8
    $tail_start -= 1 - $tail_start;
    file_seek($fastx, int($file_size * $tail_start));
    $count = read_records($fastx);
  }
  if ($count < $size) {

    # seek to beginning of file, remove first character
    seek $fastx->fh, 0, 0;
    getc $fastx->fh;
    $count = read_records($fastx);
  }
}
else {
  $count = read_records($fastx);
}

for my $itr (($count - $size) .. ($count - 1)) {
  $bin[$itr % $size]->print(width => $width);
}

exit;

sub file_seek {
  my ($fastx, $location) = @_;
  seek $fastx->fh, $location, 0;
  my $temp = $fastx->next_seq;
}

sub read_records {
  my ($fastx) = @_;
  preallocate_array(\@bin, $size);
  $count = 0;
  while (my $seq = $fastx->next_seq) {
    $bin[$count % $size] = $seq;
    $count++;
  }
  return $count;
}

sub preallocate_array {
  my ($array, $size) = @_;
  $#{$array} = $size - 1;
}

sub seekable {
  my ($files) = @_;
  for my $file (@{$files}) {
    return if $file eq '-' or $file =~ m{\|};
  }
  return 1;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

fasta_tail.pl - tail of fastx formated files

=head1 SYNOPSIS

fasta_tail.pl [options] [file ...]

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

B<fasta_tail.pl> tail of fastx formated files

=cut

