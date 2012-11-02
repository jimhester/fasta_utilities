#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/18/2011
# Title:mergeRecords.pl
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
# mergeRecords.pl
###############################################################################

use readFastx;

my $fullSequence;

my $file = readFastx->new();

while(my $seq = $file->next_seq){
  $fullSequence .= $seq->sequence;
  $name = $seq->header unless $name;
}

my $full = readFastx::Fasta::Seq->new();
$full->header = $name;
$full->sequence = $fullSequence;
$full->print(undef, $width);

#local $/ = ">";
#
#while(<>){
#  my $headerEnd = index($_,"\n");
#  my $header = substr($_,0,$headerEnd-1);
#  my $sequence = substr($_,$headerEnd+1,-2);
#  $sequence =~ tr/\n//d;
#  $fullSequence .= $sequence;
#  $name = $header unless $name;
#}
#
#print ">$name\n" . wrapLines($fullSequence);
#
#sub wrapLines{
#  my($line) = shift;
#  my ($num) = shift || 80;
#  my $curr = 0;
#  my $out;
#  while($curr < length($line)){
#    $out .= substr($line,$curr,$num) . "\n";
#    $curr+=$num;
#  }
#  return $out;
#}


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

mergeRecords.pl - merges all the input records into one record, by defualt uses the name of the first record, but can be changed with -name

=head1 SYNOPSIS

mergeRecords.pl [options] [file ...]

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

B<mergeRecords.pl> merges all the input records into one record, by defualt uses the name of the first record, but can be changed with -name

=cut

