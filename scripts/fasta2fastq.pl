#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/18/2010
# Title:fastq2fasta.pl
# Purpose:this script converts fastq to fasta
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $quality = "c";
my $pssm;
my $nowrap;
my $errorFactor = 0;
GetOptions('errorFactor=i' => \$errorFactor, 'nowrap' => \$nowrap,'quality=s' => \$quality, 'pssm=s' => \$pssm, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# fastq2fasta.pl
###############################################################################
use ReadFastx;
sub wrapLines($$);
use Storable;
#use qual_creator;
my $qual;
#$qual = qual_creator->new(pssm_filename => $pssm) if $pssm;

my $file = ReadFastx->new();
while(my $seq = $file->next_seq){
  my $sequence = uc($seq->sequence);
  my $qualityStr;
  my $sequenceStr;
  if($pssm){
#    if($errorFactor == 0){
#      $sequenceStr = $sequence;
#      for my $itr(0..(length($sequence)-1)){
#        my($quality) = $qual->getQual($itr,substr($sequence,$itr,1));
#        $qualityStr .= $quality;
#      }
#    } else {
#      for my $itr(0..(length($sequence)-1)){
#        my($base,$quality) = $qual->getBoth($itr,substr($sequence,$itr,1),$errorFactor);
#        $qualityStr .= $quality;
#        $sequenceStr .= $base;
#      }
#    }
  } else {
    $qualityStr = ($quality) x length($sequence);
    $sequenceStr = $sequence;
  }
  my $fastq = ReadFastx::Fastq::Seq->new();
  $fastq->header=$seq->header;
  $fastq->sequence = $sequenceStr;
  $fastq->quality = $qualityStr;
  $fastq->print;
}
#sub wrapLines($$);
#$/ = ">";
#my $first = <>;
#use Storable;
#use qual_creator;
#my $qual;
#$qual = qual_creator->new(pssm_filename => $pssm) if $pssm;
#
#use JimBar;
#my $bar = JimBar->new();
#while(<>){
#  chomp;
#  if(/^(.*?)[\n\t](.*?)$/s){
#    my ($header, $sequence) = ($1,$2);
#    $sequence = uc($sequence);
#    $sequence =~ tr/\n//d;
#    my $qualityStr;
#    my $sequenceStr;
#    if($pssm){
#      if($errorFactor == 0){
#	$sequenceStr = $sequence;
#	for my $itr(0..(length($sequence)-1)){
#	  my($quality) = $qual->getQual($itr,substr($sequence,$itr,1));
#	  $qualityStr .= $quality;
#	}
#      }
#      else{
#	for my $itr(0..(length($sequence)-1)){
#	  my($base,$quality) = $qual->getBoth($itr,substr($sequence,$itr,1),$errorFactor);
#	  $qualityStr .= $quality;
#	  $sequenceStr .= $base;
#	}
#      }
#    }
#    else{
#      $qualityStr = ($quality) x length($sequence);
#      $sequenceStr = $sequence;
#    }
#    print "\@$header\n$sequenceStr\n+$header\n$qualityStr\n";
#  }
#}
#$bar->done();
#sub wrapLines($$){
#  my($line,$num) = @_;
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

fastq2fasta.pl - this script converts fastq to fasta

=head1 SYNOPSIS

fastq2fasta.pl [options] [file ...]

Options:
      -nowrap
      -quality
      -pssm
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-errorFactor>

factor to multiply the error rate by, only applicable if using a pssm.  The error
rate used will be the modeled error rate * the error factor.  If you want no errors modeled
, set the error factor to be 0, which is the default.

=item B<-nowrap>

Do not wrap the output to 80 characters

=item B<-quality>

Use the specified character for all the qualities

=item B<-pssm>

Use the pssm file specified to create qualities

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<fastq2fasta.pl> this script converts fastq to fasta

=cut

