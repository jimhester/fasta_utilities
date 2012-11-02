#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:04/02/2010
# Title:/home/hesterj/fastaUtilities/sam2fastq.pl
# Purpose:Converts a sam file to fastq file(s)
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $illumina;
my $pair;
GetOptions('pair=i' => \$pair, 'illumina|I' => \$illumina,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# /home/hesterj/fastaUtilities/sam2fastq.pl
###############################################################################

while(<>){
  if(!/^@/){
    my($name, $bit_field, $chromosome, $position, $quality, $cigar, $mate_chromosome, $mate_position,$value,$readSequence, $readQuality, $mismatchPositions) = split;
    if($illumina){
      $readQuality = pack("c*",map { $_ + 31 } unpack("c*",$readQuality));
    }
    if($bit_field & 0x10){
      $readSequence = revComp($readSequence);
    }
    if(($bit_field & 0x40) or $pair == 1){
      $name .= "/1";
    }
    if(($bit_field & 0x80) or $pair == 2){
      $name .= "/2";
    }
    print "\@$name\n$readSequence\n+$name\n$readQuality\n";
  }
}

sub revComp {
  my $seq = shift;
  $seq =~ tr/ACGT/TGCA/;
  return(reverse $seq);
}


###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

/home/hesterj/fastaUtilities/sam2fastq.pl - this script gets the sequnece lengths from a sam file

=head1 SYNOPSIS

/home/hesterj/fastaUtilities/sam2fastq.pl [options] [file ...]

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

B</home/hesterj/fastaUtilities/sam2fastq.pl> this script gets the sequnece lengths from a sam file

=cut

