#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/04/2011
# Title:sortFasta.pl
# Purpose:sort a fasta file by header name, length or sequence
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my %options;
GetOptions(\%options, 'chr|c','sequence|s', 'header|h' ,'length|l' ,'reverse|r' ,'disk' ,'help|?' => \$help, man => \$man) or pod2usage(2);
#GetOptions('chr|c' => \$chromosome, 'sequence|s' => \$sequence, 'header|h' => 
#\$header,'length|l' => \$length,'reverse|v' => \$reverse,'disk' => 
#\$onDisk,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: Please specify a sort criteria") unless keys %options;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# sortFasta.pl
###############################################################################

#this script sorts a fasta file by various traits by transforming the records 
#into lines and passing them to gnu/sort

use Data::Dumper;

my $arguments = "--" . join(" --",keys %options);
my $sortArgs='-z';
$sortArgs .= ' -r' if exists $options{reverse};
$sortArgs .= ' -n' if exists $options{length} or exists $options{chr};
my $command ="| ~/fu/formatForSort.pl $arguments |sort $sortArgs| ~/fu/formatAfterSort.pl $arguments";
#print STDERR $command."\n";
open OUT, "$command";

while(<>){
  print OUT;
}
#my $fasta;
#
#if(not $header and not $sequence and not $length and not $chromosome){
##  $header=1;
#}
#
#my @data;
#
#my $readingFunction = getReadingFunction();
#
#&$readingFunction();
#
#my $sortFun = getSortingFunction();
#
#my $printFun = getPrintingFunction();
#
#for my $rec (sort $sortFun @data){
#  &$printFun($rec);
#}
#
#sub printData{
#  my $header = shift;
#  print ">$header\n",$header->{sequence},"\n";
#}
#
#sub getPrintingFunction{
#  if($fasta){
#    if(!$onDisk){
#      return(\&printFastaInMemory);
#    }
#    else{
#      return(\&printFastaOnDisk);
#    }
#  }
#  else{
#    if(!$onDisk){
#      return(\&printFastqInMemory);
#    }
#    else{
#      return(\&printFastqOnDisk);
#    }
#  }
#}
#sub getReadingFunction{
#  local $/=\1;
#  my $firstChar =<>;
#  if($firstChar eq ">"){
#    $fasta = 1;
#    if(!$onDisk){
#      return(\&readFastaInMemory);
#    }
#    else{
#      return(\&readFastaOnDisk);
#    }
#  } 
#  elsif($firstChar eq "@"){
#    if(!$onDisk){
#      return(\&readFastqInMemory);
#    }
#    else{
#      return(\&readFastqOnDisk);
#    }
#  }
#  else{
#    die "not a fasta or fastq file";
#  }
#}
#  
#
#sub getSortingFunction{
#  if($header){
#    if(!$reverse){
#      return(\&sortHeader);
#    }
#    else{
#      return(\&sortHeaderR);
#    }
#  }
#  elsif($sequence){
#    if(!$reverse){
#      return(\&sortSequence);
#    }
#    else{
#      return(\&sortSequence);
#    }
#  }
#  elsif($length){
#    if(!$reverse){
#      return(\&sortLength);
#    }
#    else{
#      return(\&sortLengthR);
#    }
#  } elsif($chromosome){
#    if(!$reverse){
#      return(\&sortChrAsc);
#    } else {
#      return(\&sortChrDsc);
#    }
#  } die "no sorting function selected!\n";
#}
#
#sub sortHeader{
#  return($a->{header} cmp $b->{header});
#}
#sub sortHeaderR{
#  return($b->{header} cmp $a->{header});
#}
#sub sortSequence{
#  return($a->{sequence} cmp $b->{sequence})
#}
#sub sortSequenceR{
#  return($b->{sequence} cmp $a->{sequence})
#}
#sub sortLength{
#  return($a->{length} <=> $b->{length})
#}
#sub sortLengthR{
#  return($b->{length} <=> $a->{length})
#}
#sub sortChrAsc{
#  if($a->{header} =~ /chr([0-9]+)/){
#    my $first = $1;
#    if($b->{header} =~ /chr([0-9]+)/){
#      my $second = $1;
#      return($first <=> $second || $a->{header} cmp $b->{header});
#    }
#    return(-1);
#  }
#  if($b->{header} =~ /chr([0-9]+)/){
#    return(1);
#  }
#  return($a->{header} cmp $b->{header});
#}
#
#sub sortChrDsc{
#  if($a->{header} =~ /chr([0-9]+)/){
#    my $first = $1;
#    if($b->{header} =~ /chr([0-9]+)/){
#      my $second = $1;
#      return($second <=> $first || $b->{header} cmp $a->{header});
#    }
#    return(1);
#  }
#  if($b->{header} =~ /chr([0-9]+)/){
#    return(-1);
#  }
#  return($b->{header} cmp $a->{header});
#}
#sub readFastaInMemory{
#  local $/ = ">";
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*)$/s){
#      my ($title, $sequence) = ($1,$2);
#      $sequence =~ tr/\n//d;
#      my %rec;
#      $rec{header} = $title;
#      $rec{sequence}=$sequence;
#      $rec{length}=length($sequence);
#      push @data, \%rec;
#    }
#  }
#}
#sub readFastaOnDisk{
#  local $/ = ">";
#  die "Cannot use on disk when reading from STDIN" if($ARGV) eq "-";
#  my $pos = tell;
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*)$/s){
#      my ($title, $sequence) = ($1,$2);
#      $sequence =~ tr/\n//d;
#      my %rec;
#      $rec{header} = $title;
#      $rec{sequence}=substr($sequence,0,$numCompare);
#      $rec{length}=length($sequence);
#      $rec{file} = $ARGV;
#      $rec{pos} = $pos;
#      push @data, \%rec;
#    }
#    $pos = tell;
#  }
#}
#sub readFastqInMemory{
#  while(defined (my $title = <> )and
#        defined (my $sequence = <>) and
#        defined (my $header2  = <>) and
#        defined (my $quality = <>)){
#    my %rec;
#    $title =~ tr/@\n//d;
#    $rec{header} = $title;
#    $rec{sequence}=substr($sequence,0,-1);
#    $rec{quality}=substr($quality,0,-1);
#    $rec{length}=length($sequence);
#    push @data, \%rec;
#  }
#}
#sub readFastqOnDisk{
#  local $/ = "@";
#  my $pos = tell;
#  while(<>){
#    chomp;
#    if(/^(.*?)\n(.*?)\n\+.*?\n(.*?)$/s){
#      my ($title, $sequence,$quality) = ($1,$2,$3);
#      $sequence =~ tr/\n//d;
#      my %rec;
#      $rec{header} = $title;
#      $rec{sequence}=substr($sequence,0,$numCompare);
#      $rec{length}=length($sequence);
#      $rec{file} = $ARGV;
#      $rec{pos} = $pos;
#      push @data, \%rec;
#    }
#    $pos = tell;
#  }
#}
#sub printFastaInMemory{
#  my($rec) = @_;
#  print ">",$rec->{header},"\n",$rec->{sequence},"\n";
#}
#sub printFastqInMemory{
#  my($rec) = @_;
#  print "@",$rec->{header},"\n",$rec->{sequence},"\n+",$rec->{header},"\n",$rec->{quality},"\n";
#}
#
#sub printFastaOnDisk{
#  my($rec) = @_;
#  open IN, $rec->{file};
#  seek IN, $rec->{pos},0;
#  local $/ = ">";
#  my $read = <IN>;
#  chomp $read;
#  print ">$read";
#  close IN;
#}
#sub printFastqOnDisk{
#  my($rec) = @_;
#  open IN, $rec->{file};
#  seek IN, $rec->{pos},0;
#  local $/ = "@";
#  my $read = <IN>;
#  chomp $read;
#  print "@$read";
#  close IN;
#}


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

sortFasta.pl - sort a fasta file by header name, length or first x bp, default is 10

=head1 SYNOPSIS

sortFasta.pl [options] [file ...]

Options:
      -numCompare
      -sequence
      -header
      -length
      -reverse
      -disk
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-sequence|s>

Sort by the sequences

=item B<-header|h>

Sort by the headers

=item B<-length|l>

Sort by the sequence length

=item B<-reverse|r>

Sort decending

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<sortFasta.pl> sort a fasta file by header name, length or first x bp, default is 10

=cut

