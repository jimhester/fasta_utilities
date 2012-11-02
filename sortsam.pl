#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/17/2010
# Title:sortsam.pl
# Purpose:this script uses gnu sort to sort a sam file by chromosome and location, it properly avoids the header
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
# sortsam.pl
###############################################################################

# if(not -e $ARGV[0]){
#   die("$ARGV[0] does not exist")
# }
# my $headerLines = 0;
# while(<>){
#   if(/^@/){
#     $headerLines++;
#   }
#   else{
#     last;
#   }
# }
# my ($prefix,$suffix) = ('') x 2;
# if($ARGV =~ /(.+)(\..*$)/){
#   ($prefix,$suffix) = ($1,$2);
# }
# else{
#   $prefix = $ARGV;
# }

# my $name = "$prefix.sorted$suffix";

#system("sort -S 90% -l" .($headerLines)." -k3,3 -k4,4n $ARGV > $name"); #this requires the sort have line skipping implemented
use IO::Handle;
#select STDOUT; $| = 1;s
open SORT, "|sort -S 90% -k3,3 -k4,4n -k1,1";
open UNMAPPED, ">.unmapped";
my @headers;
while(<>){
  if(/^@/o){
    my $line = $_;
    my @sq;
    while($line =~ /\@SQ/){
      push @sq, $line;
      $line = <> || last;
    }
    if(@sq){
      @sq = sort @sq;
      print @sq;
      print $line; #print the last line after the sqs
    }
    else{
      print $_;
    }
  }
  else{
    my($first,$second,$third) = split;
    if($third ne "*"){
      print SORT $_;
    }
    else{
      print UNMAPPED $_;
    }
  }
}
STDOUT->flush;
close SORT;
system("cat .unmapped");
system("rm .unmapped");
# my $file = shift;

# if($file =~ /\.bam/i){
#   my @headers = `samtools view -H $file`;
#   my @sq;
#   for my $header(@headers){
#     if($header =~ /\@SQ/){
#       push @sq, $header;
#     }
#     else{
#       print $header;
#     }
#   }
#   @sq = sort @sq;
#   print @sq;
# }

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

sortsam.pl - this script uses gnu sort to sort a sam file by chromosome and location, it properly avoids the header

=head1 SYNOPSIS

sortsam.pl [options]

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

B<sortsam.pl> this script uses gnu sort to sort a sam file by chromosome and location, it properly avoids the header

=cut

