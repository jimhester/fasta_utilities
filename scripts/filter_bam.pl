#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 11 09:11:28 AM
# Last Modified: 2013 Jan 11 01:34:33 PM
# Title:filter_bam.pl
# Purpose:Filters two singely mapped bam files by orientation and mapping
# quality
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man            = 0;
my $help           = 0;
my $quality_cutoff = 30;
GetOptions( 'quality=i' => \$quality_cutoff,
            'help|?'    => \$help,
            man         => \$man )
  or pod2usage(2);
pod2usage(2) if $help;
pod2usage( -verbose => 2 ) if $man;
pod2usage("$0: No files given.") if ( ( @ARGV == 0 ) && ( -t STDIN ) );
###############################################################################
# filter_bam.pl
###############################################################################

my @SAM_FIELDS =
  qw(qname flag rname position mapq cigar rnext pnext tlen sequence quality optional);

#get header from first file

my $header = read_header( $ARGV[0] );

my $first = open_sam(shift);

my $second = open_sam(shift);

print $header;

while (     my $first_align = parse_sam($first)
        and my $second_align = parse_sam($second) )
{
  if (     is_mapped($first_align)
       and is_mapped($second_align)
       and $first_align->{mapq} > $quality_cutoff
       and $second_align->{mapq} > $quality_cutoff
       and has_correct_orientation( $first_align, $second_align ) )
  {
    print $first_align->{raw}, $second_align->{raw};
  }
}

sub is_mapped {
  my ($align) = @_;
  return ( ( $align->{flag} & 0x4 ) == 0 );
}

sub read_header {
  my ($filename) = @_;
  my $header;
  if ( $filename =~ m{\.bam} ) {    #process bam header
    local $/ = undef;
    open my $header_file, "samtools view -H $filename |"
      or die "$!:Could not open $filename\n";
    $header = <$header_file>;
    close $header_file;
  }
  else {                            #process sam header
    open my $header_file, "<", "$filename"
      or die "$!:Could not open $filename\n";
    while (<$header_file>) {
      last if not m{^@};
      $header .= $_;
    }
  }
  return ($header);
}

sub open_sam {
  my ($filename) = @_;

  #use samtools to pipe if bam, othewise just cat
  $filename =
    $filename =~ m{.*\.bam\s*$}
    ? "samtools view $filename|"
    : "cat $filename|";

  #pipe to sort to sort by the read name
  open my $in, "$filename sort -k1,1 |";
  return $in;
}

sub parse_sam {
  my ($fh) = @_;
  my $line = <$fh>;
  return unless $line;
  my $itr = 0;
  my %ref;
  for my $value ( split /[\t\n]/, $line ) {
    if ( $itr < @SAM_FIELDS - 1 ) {
      $ref{ $SAM_FIELDS[$itr] } = $value;
    }
    else {
      my ( $tag, $val ) = $value =~ m{([A-Z0-9]+):(.*)};
      $ref{optional}{$tag} = $val;
    }
    $itr++;
  }
  $ref{raw} = $line;
  return \%ref;
}

sub has_correct_orientation {
  my ( $first, $second ) = @_;

  #false if on different chromosomes
  return if $first->{rname} ne $second->{rname};

  #swap if the second comes before the first
  if ( $first->{position} > $second->{position} ) {
    my $temp = $first;
    $first  = $second;
    $second = $temp;
  }

  #false if the sequences overlap
  return if $second->{position} < align_end($first);

  #return if the reads are in proper orientation
  # the read with the lowest start has to be on the plus strand
  return ( ( $first->{flag} & 0x10 ) == 0 and ( $second->{flag} & 0x10 ) );
}

sub align_end {
  my $align = shift;
  return $align->{end} if exists $align->{end};
  my $end = $align->{position};
  while ( $align->{cigar} =~ /([0-9]+)([MIDNSHPX=])/g ) {
    my ( $num, $operation ) = ( $1, $2 );
    if ( $operation =~ /[MDN=X]/ ) {
      $end += $num;
    }
  }
  $align->{end} = $end;
  return $end;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

filter_bam.pl - Filters two singely mapped bam files by orientation and mapping 
# quality

=head1 SYNOPSIS

filter_bam.pl [options] [file ...]

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

B<filter_bam.pl> Filters two singely mapped bam files by orientation and mapping 
# quality

=cut

