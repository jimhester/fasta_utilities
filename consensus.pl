#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 18 03:09:16 PM
# Last Modified: 2013 Jan 31 08:29:49 AM
# Title:consensus.pl
# Purpose:get consensus cDNA from a bam file and gff gene annotation
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man  = 0;
my $help = 0;
my $reference_fill;
GetOptions('reference_fill' => \$reference_fill, 'help|?' => \$help, man => \$man ) or pod2usage(2);
pod2usage(2) if $help;
pod2usage( -verbose => 2 ) if $man;
pod2usage("$0: No files given.") if ( ( @ARGV == 0 ) && ( -t STDIN ) );
###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map {
  s/(.*\.gz)\s*$/pigz -dc < $1|/;
  s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;
  $_
} @ARGV;
###############################################################################
# consensus.pl
###############################################################################

my $genome_filename = shift;

my $bed_filename = shift;

my $bam_filename = shift;

my %bed = read_bed($bed_filename);

my %reference = read_reference($genome_filename);

get_cDNA();

#vivax06 385497  385541  PVX_110810.t01  .       -
#vivax06 385632  385706  PVX_110810.t01  .       -
#vivax06 385924  386003  PVX_110810.t01  .       -
#vivax06 386108  389067  PVX_110810.t01  .       -
#vivax06 389202  389259  PVX_110810.t01  .       -
sub get_cDNA {
  #setup and print headers
  my @bases = qw(A C G T N);
  my $command = "samtools mpileup -d 1000000 -f $genome_filename -l $bed_filename $bam_filename |";
  open my $in, $command or die "$!: Could not open command\n";
    
  my %sequences;
  while(<$in>){
    #parse mpileup
    my($chr,$pos,$ref,$coverage,$reads,$qualities) = split;
    $sequences{$chr}{last} = 0 unless exists $sequences{$chr}; # initialize last position
    $reads = uc $reads; #make all letters uppercase
    $reads =~ s/[.,]/$ref/g; #change ref bases to ref letter
    $reads =~ s/\^.//g; #remove read starts and mapping quality
    $reads =~ s/\$//g; #remove read ends
    $reads =~ s/[\+\-]([0-9]+)(??{"\\w{$^N}"})//g; #remove indels

    #print base counts and raf
    my %counts;
    for my $base(@bases){
      my $count = $reads =~ s/$base/$base/g;
      $counts{$base} = $count ? $count : 0;
    }

    $sequences{$chr}{sequence} .= fill($sequences{$chr}{last}+1, $pos, $chr);
    my $consensus_base = most_frequent_base(\%counts);
    $sequences{$chr}{sequence} .= $consensus_base;
    $sequences{$chr}{last} = $pos;
  }

  for my $chr (keys %sequences){
    if(exists $bed{$chr} and $bed{$chr} > $sequences{$chr}{last}+1){
      $sequences{$chr}{sequence} .= fill($sequences{$chr}{last}+1, $bed{$chr}, $chr);
    }
  }
      
  open my $out, "| ~/fu/wrap.pl" or die "$!: Could not open file\n";
  for my $name (keys %sequences){
    print $out ">$name\n$sequences{$name}{sequence}\n";
  }
}

sub most_frequent_base{
  my($hash_ref) = @_;
  return (sort { $hash_ref->{$b} <=> $hash_ref->{$a} } keys %{ $hash_ref })[0];
}

sub read_bed{
  my($filename) = @_;
  my %bed;
  open my $in, "<", "$filename" or die "$!:Could not open $filename\n";
  while(<$in>){
    my($chr,$start,$end) = split;
    if(not exists $bed{$chr} or $bed{$chr} < $end){
      $bed{$chr} = $end;
    }
  }
  return %bed;
}

sub read_reference{
  my($filename) = @_;
  my %ref;
  if($reference_fill){
    my $fastx = ReadFastx->new($filename);
    while(my $seq = $fastx->next_seq){
      $ref{$seq->header}=$seq; 
    }
  }
  return %ref;
}
sub fill{
  my($start, $end, $chr) = @_;
  my $fill='';
  if($reference_fill){
    die "$chr not in $genome_filename" unless exists $reference{$chr};
    $fill = substr($reference{$chr}, $start, ($end - $start));
  } 
  else {
    $fill = 'n' x ($end - $start); #pad with n's if nesseseary
  }
  return $fill;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

consensus.pl - get consensus cDNA from a bam file and gff gene annotation

=head1 SYNOPSIS

consensus.pl [options] [file ...]

Options:
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-reference_fill>

Use the reference to fill uncovered bases rather than Ns

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<consensus.pl> get consensus cDNA from a bam file and gff gene annotation

=cut

