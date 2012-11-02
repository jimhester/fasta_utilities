#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:07/27/2010
# Title:bisConv.pl
# Purpose:this script bisulfate converts the sequences given to it
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
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# bisConv.pl
###############################################################################
local $/=\1;
my $firstChar =<>;
if($firstChar == "@"){
  $/ = "\n";
  print $firstChar;
  while(defined (my $seqHeader = <>) and 
	defined (my $sequence = <>) and 
	defined (my $qualHeader = <>) and 
	defined (my $quality = <>)){
    chomp for($seqHeader, $sequence, $qualHeader,$quality);
    $sequence =~ tr/Cc/Tt/d;
    print("$seqHeader\n$sequence\n$qualHeader\n$quality\n");
  }
} elsif($firstChar == ">") {
  $/ = ">";
  print $firstChar;
  while(<>){
    my $headerEnd = index($_,"\n");
    my $header = substr($_,0,$headerEnd-1);
    my $sequence = substr($_,$headerEnd+1,-2);
    $sequence =~ tr/Cc/Tt/d;
    print("$header\n$sequence\n");
  }
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

bisConv.pl - this script bisulfate converts the sequences given to it

=head1 SYNOPSIS

bisConv.pl [options] [file ...]

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

B<bisConv.pl> this script bisulfate converts the sequences given to it

=cut

