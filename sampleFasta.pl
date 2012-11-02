#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:10/21/2009
# Title:sampleFasta.pl
# Purpose:this script randomly samples a fasta or fastq file with or without replacement
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $replace;
my $sampleNum = 10;
GetOptions('num|n=i' => \$sampleNum, 'replace|r' => \$sampleNum, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# sampleFasta.pl
###############################################################################
sub procFasta($);
sub procRecord($);

my $firstChar;

my $numFiles = scalar @ARGV;
my %used;

my @records = ();
my @counts = ();
print STDERR "Sampling $sampleNum sequences from $numFiles files\n";
for my $filename (@ARGV){
  print STDERR "Sampling $filename\n";
  open FILE, $filename or die $!;
  local $/=\1;
  $firstChar =<FILE>;
  procRecord($filename);
}


sub procRecord($){
  my $file = shift;
  my @records = ();
  getRecords($file,\@records);
  my $count = 0;
  $/ = $firstChar;
  while($count < $sampleNum/$numFiles and @records){
    my $test = int(rand(@records));
    if(not exists $used{$test}){
      seek FILE, $records[$test],0;
      my $first = <FILE>;
      my $record = <FILE>;
      chomp $record;
      print "$firstChar$record";
      if(not $replace){
	$used{$test}=();
      }
      $count++;
    }
  }
  if($count < $sampleNum){
    print STDERR "\nNot enough records for number of samples, use -replace to sample with replacement\n";
  }
}
sub getRecords($){
  my $file = shift;
  my $recordPtr = shift;
  my $temp = $/;
  $/ = "\n";
  @{ $recordPtr } = map{($_) = split /:/}  `grep -boF \"$firstChar\" $file`;
  $/ = $temp;
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

sampleFasta.pl - this script randomly samples a fasta or fastq file with or without replacement

=head1 SYNOPSIS

sampleFasta.pl [options] [file ...]

Options:
      -num,n
      -replace,r
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-num,n>

Set the number of records to get, default is 10

=item B<-replace,r>

Sets to sample with replacement, default is without replacement

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<sampleFasta.pl> this script randomly samples a fasta or fastq file with or without replacement

=cut

