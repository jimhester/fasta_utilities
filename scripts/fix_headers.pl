#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:12/02/2010
# Title:fixFastaHeaders.pl
# Purpose:this script fixes the fastx header by removing spaces and optionally appending a suffix
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $suffix ='';
my $prefix = '';
my $separator = '|';
my $space = '_';
GetOptions('space=s' => \$space, 'separator=s' => \$separator, 'prefix=s' =>
\$prefix, 'suffix=s' => \$suffix, 'help|?' => \$help, man => \$man) or
pod2usage(2); pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# /home/hesterj/fastaUtilities/fix_headers.pl
###############################################################################
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

my $fastx = ReadFastx->new();

while(my $seq = $fastx->next_seq()){
  my $header = $seq->header;
  $header = $prefix . $separator . $header if $prefix;
  $header = $header . $separator . $suffix if $suffix;
  $header =~ s/ /$space/g;
  $header =~ tr/-+,'//d;
  $seq->header($header);
  $seq->print;
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

fix_headers.pl - this script fixes the fastx header by removing spaces and optionally appending a suffix

=head1 SYNOPSIS

fix_headers.pl [options] [file ...]

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-space>

Character to substitute spaces by.

=item B<-separator>

Character to use to separate the prefix and suffix

=item B<-prefix>

Prefix to prepend

=item B<-suffix>

Suffix to append

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B</home/hesterj/fastaUtilities/fix_headers.pl> this script fixes the fastx header by removing spaces and optionally appending a suffix

=cut

