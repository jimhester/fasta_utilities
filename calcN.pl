#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/04/2011
# Title:calcN.pl
# Purpose:takes a file of fasta lengths, or a fasta or fastq file directly, and calculates the nX of the file, by default N50
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my @Ns;
my $low=-1;
my $high=1000e6;
GetOptions('low|l=i' => \$low, 'high|h=i' => \$high, 'N=s' => \@Ns, 'help|?' => \$help, man => \$man ) or pod2usage(2);
pod2usage(2) if $help;
pod2usage( -verbose => 2 ) if $man;
pod2usage("$0: No files given.") if ( ( @ARGV == 0 ) && ( -t STDIN ) );
###############################################################################
# calcN.pl
###############################################################################

@Ns = split /,/, join( ',', @Ns );
@Ns = (50) unless @Ns;
@Ns = sort { $a <=> $b } @Ns;

use ReadFastx;

my %lengths;
my $fastx = ReadFastx->new();

my $totalLength = 0;
while ( my $seq = $fastx->next_seq ) {
  my $length = length( $seq->sequence );
  if($length >= $low and $length <= $high){
    push @{ $lengths{$fastx->current_file}{lengths} }, $length;
    $lengths{$fastx->current_file}{total} += $length;
  }
}

print join( "\t", "file", "min", @Ns,"median", "max", "total", "num" ) . "\n";
for my $file ( sort keys %lengths ) {
  my $cumSum = 0;
  my $Nitr = 0;
  @{$lengths{$file}{lengths}} = sort {$b <=> $a} @{ $lengths{$file}{lengths} };
  printf "%s\t%g",$file,$lengths{$file}{lengths}[-1];
  my $totalLength = $lengths{$file}{total};
  my $itr=0;
  for my $len ( @{ $lengths{$file}{lengths} } ) {
      $cumSum += $len;
      if ( $Nitr < @Ns and $cumSum > $Ns[$Nitr] * .01 * $totalLength ) {
          printf "\t%g",$len;
          $Nitr++;
      }
      $itr++;
  }
  while($Nitr < @Ns){ #print all Ns as biggest contig if not done
    printf "\t%g",$lengths{$file}{lengths}[0];
    $Nitr++;
  }
  my $num_lengths = scalar @{ $lengths{$file}{lengths} };
  #true definition of the median
  my $median =
      $num_lengths % 2 == 1
    ? $lengths{$file}{lengths}[$num_lengths / 2]
    : ($lengths{$file}{lengths}[int($num_lengths / 2)-1] + $lengths{$file}{lengths}[int($num_lengths / 2)]) / 2;
  print join("\t", '', map { sprintf("%g", $_) } ($median, $lengths{$file}{lengths}[0], $totalLength, scalar @{$lengths{$file}{lengths}})), "\n";
}
exit;
###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

calcN.pl - takes a file of fasta lengths, or a fasta or fastq file directly, and calculates the nX of the file, by default N50

=head1 SYNOPSIS

calcN.pl [options] [file ...]

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

B<calcN.pl> takes a file of fasta lengths, or a fasta or fastq file directly, and calculates the nX of the file, by default N50

=cut

