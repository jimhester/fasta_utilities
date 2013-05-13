#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 Apr 11 01:04:46 PM
# Last Modified: 2013 May 07 11:10:56 AM
# Title:sequence_counts.pl
# Purpose:generates sequence counts using a hash
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my %args = (start => 0, number=> 10);
GetOptions(\%args, 'start=i', 'length=i', 'number=i', 'paired', 'help|?', 'man') or pod2usage(2);
pod2usage(2) if exists $args{help};
pod2usage(-verbose => 2) if exists $args{man};
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# sequence_counts.pl
###############################################################################
use ReadFastx;

#TODO use bloom filter to use less memory?
my %count = ();
my $total=0;

if(exists $args{paired}){
  paired();
}
else {
  single();
}

for my $sequence( top_keys(\%count, $args{number})){
  printf "$sequence\t$count{$sequence}\t%.2f%%\t$total\n", $count{$sequence}/$total*100;
}
exit;
sub paired{

  while(@ARGV){
    my($first, $second) = (shift @ARGV, shift @ARGV);
    my $first_fastx = ReadFastx->new($first);
    my $second_fastx = ReadFastx->new($second);
    while(my $seq1 = $first_fastx->next_seq and my $seq2 = $second_fastx->next_seq){
      my $sub_sequence1 = substring($seq1);
      my $sub_sequence2 = substring($seq2);
      $count{"$sub_sequence1-$sub_sequence2"}++;
      $total++;
    }
  }
}
sub single{

  my $fastx = ReadFastx->new();
  while(my $seq = $fastx->next_seq){
    my $sequence = substring($seq);
    $count{$sequence}++;
    $total++;
  }
}

sub substring{
  my($seq) = @_;
  return scalar exists $args{length}
  ? substr( $seq->sequence, $args{start}, $args{length} )
  : substr( $seq->sequence, $args{start} );
}
sub top_keys {
  my ( $hash_ref, $count ) = @_;
  my @keys = keys %{$hash_ref};
  return ( map            { $_->[0] }
             reverse sort { $a->[1] <=> $b->[1] }
             map          { [ $_, $hash_ref->{$_} ] } @keys
         )[ 0 .. min( $count - 1, $#keys ) ];
}
sub min{
  return $_[0] if $_[0] < $_[1];
  return $_[1];
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

sequence_counts.pl - generates sequence counts using a hash

=head1 VERSION

0.0.1

=head1 USAGE

Options:
      -length
      -number
      -start
      -help
      -man               for more info

=head1 OPTIONS

=over

=item B<-length>

length of the read to count.

=item B<-start>

start position of the read to count.

=item B<-number>

number of top results to return.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<sequence_counts.pl> generates sequence counts using a hash

=cut

