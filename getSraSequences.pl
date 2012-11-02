#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:05/15/2012
# Title:getSraSequences.pl
# Purpose:this script downloads the sra sequences from NCBI using aspera and outputs a fastq file
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $asperaDir = "/home/hesterj/.aspera";
GetOptions('aspera=s' => \$asperaDir, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# getSraSequences.pl
###############################################################################

my $link = shift;
my $description = shift;

if($link =~ m!ftp://([^/]+)(/.+/)(.+)!){
  my($server,$path,$dataset)=($1,$2,$3);
  my $command = "$asperaDir/connect/bin/ascp --overwrite=never -k2 -i $asperaDir/connect/etc/asperaweb_id_dsa.putty -QT -L . -l 500m anonftp\@$server:$path$dataset .";
  print STDERR $command;
  system($command);
  system("ln -s $dataset $description") if $description;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

getSraSequences.pl - this script downloads the sra sequences from NCBI using aspera and outputs a fastq file

=head1 SYNOPSIS

getSraSequences.pl [options] [file ...]

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

B<getSraSequences.pl> this script downloads the sra sequences from NCBI using aspera and outputs a fastq file

=cut

