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
my $low  = -1;
my $high = 1000e6;
GetOptions( 'low|l=i'  => \$low,
            'high|h=i' => \$high,
            'N=s'      => \@Ns,
            'help|?'   => \$help,
            man        => \$man )
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage( -verbose => 2 ) if $man;
pod2usage("$0: No files given.") if ( ( @ARGV == 0 ) && ( -t STDIN ) );
###############################################################################
# calcN.pl
###############################################################################

@Ns = split /,/, join( ',', @Ns );
@Ns = (50) unless @Ns;
@Ns = sort { $a <=> $b } @Ns;

use FindBin;
use lib $FindBin::RealBin."/../";
use ReadFastx;

my $fastx = ReadFastx->new(files=>\@ARGV);

#initialize variables
my $total = 0;
my @lengths;
my $prev_file = '';

print join( "\t", "file", "min", @Ns,"median", "max", "total", "num" ) . "\n";
while ( my $seq = $fastx->next_seq ) {

  #initialize lengths if a new or first file, print previous if new
  if($fastx->current_file ne $prev_file){
    if($prev_file ne ''){ #this is only true the first iteration
      print_statistics($prev_file, \@lengths, $total);
    }
    @lengths=();
    $total=0;
    $prev_file = $fastx->current_file;
  }

  my $length = length( $seq->sequence );

  #add length if valid
  if ( $length >= $low and $length <= $high ) {
    push @lengths, $length;
    $total+=$length;
  }
}
#print statistics for the last file
print_statistics($prev_file, \@lengths, $total);

exit;

sub print_statistics {
  my ( $file, $lengths, $total ) = @_;
  my $cumSum = 0;
  my $Nitr   = 0;
  @{ $lengths } = sort { $b <=> $a } @{ $lengths };
  printf "%s\t%g", $file, $lengths[-1];
  my $itr         = 0;
  for my $len ( @{ $lengths } ) {
    $cumSum += $len;
    if ( $Nitr < @Ns and $cumSum > $Ns[$Nitr] * .01 * $total ) {
      printf "\t%g", $len;
      $Nitr++;
    }
    $itr++;
  }
  while ( $Nitr < @Ns ) {    #print all Ns as biggest contig if not done
    printf "\t%g", $lengths[0];
    $Nitr++;
  }
  my $num_lengths = scalar @{ $lengths };

  #true definition of the median
  my $median =
      $num_lengths % 2 == 1
    ? $lengths[ $num_lengths / 2 ]
    : (   $lengths[ int( $num_lengths / 2 ) - 1 ]
        + $lengths[ int( $num_lengths / 2 ) ] )
    / 2;
  print join( "\t", '',
              map { sprintf( "%g", $_ ) } (
                                  $median,      $lengths[0],
                                  $total, scalar @{ $lengths }
                                          ) ),
    "\n";
}

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

