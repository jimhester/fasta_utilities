#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:06/21/2010
# Title:recordsToFiles.pl
# Purpose:this script outputs each fasta or fastq record to a file based on the file header
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
GetOptions('help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# recordsToFiles.pl
###############################################################################


local $/=\1;
my $firstChar =<>;
if($firstChar eq ">"){
  procFasta();
} 
elsif($firstChar eq "@"){
  procFastq();
}
else{
  die "not a fasta or fastq file";
}
sub procFasta{
  local $/ = ">";
  while(<>){
    chomp;
    if(/^(.*?)\n(.*)$/s){
      my ($title, $sequence) = ($1,$2);
      $sequence =~ tr/\n//d;
      open FILE, ">","$title.fa" or die $!;
      print STDERR "writing to $title.fa\n";
      printFasta($title,$sequence,\*FILE);
      close FILE;
    }
  }
}
sub procFastq{
  local $/ = "@";
  while(<>){
    chomp;
    if(/^(.*?)\n(.*?)\n\+.*?\n(.*?)\n$/s){
      my ($title, $sequence,$quality) = ($1,$2);
      $sequence =~ tr/\n//d;
      $quality =~ tr/\n//d;
      open FILE, ">","$title.fq" or die $!;
      print STDERR "writing to $title.fq\n";
      printFastq($title,$sequence,$quality,\*FILE);
      close FILE;
    }
  }
}
sub printFasta{
  my $fh = \*STDOUT;
  if(@_ == 3){
    $fh = $_[2];
  }
  print $fh ">$_[0]\n";
  print $fh wrapLines($_[1], 80);
}
sub printFastq{
  my $fh = \*STDOUT;
  if(@_ == 4){
    $fh = $_[3];
  }
  print $fh "@$_[0]\n";
  print $fh wrapLines($_[1], 80);
  print $fh "+$_[0]\n";
  print $fh wrapLines($_[2], 80);
}
sub wrapLines($$){
  my($line,$num) = @_;
  my $curr = 0;
  my $out;
  while($curr < length($line)){
    $out .= substr($line,$curr,$num) . "\n";
    $curr+=$num;
  }
  return $out;
}



###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

recordsToFiles.pl - this script outputs each fasta or fastq record to a file based on the file header

=head1 SYNOPSIS

recordsToFiles.pl [options] [file ...]

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

B<recordsToFiles.pl> this scripts outputs each fasta or fastq record to a file based on the file header

=cut

