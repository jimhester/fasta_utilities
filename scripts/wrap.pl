#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/05/2011
# Title:wrap.pl
# Purpose:limits fasta lines to 80 characters
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $width = 80;
GetOptions('n|l|width=i' => \$width, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# wrap.pl
###############################################################################
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

my $file = ReadFastx->new();

while(my $seq = $file->next_seq){
  $seq->print(width => $width);
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

wrap.pl - limits fasta lines to 80 characters

=head1 SYNOPSIS

wrap.pl [options] [file ...]

Options:
      -help
      -man               for more info
      -width

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-width>

set the amount of characters to make a new line

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<wrap.pl> limits fasta lines to 80 characters

=cut

