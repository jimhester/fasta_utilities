#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/16/2012
# Title:filter_align.pl
# Purpose:filters alignments from a bam or sam file
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my %filter;
my $strict;
GetOptions(\%filter, 'strict' => \$strict, 'query=s@', 'flag=o@', 
'rname|chromosome|reference=s@', 'position=i@', 'region=s@', 'mapq=i@', 'cigar=s@', 
'mate-rname|mate-chromosome|mate-reference=s@', 'mate-position=i@', 
'mate-region=s@', 'fragment-length=i@', 'sequence=s@', 'quality=s@', 
'quality-average=i@', 'optional=s@','length','help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# filter_align.pl
###############################################################################

use List::Util qw(sum);

# filter sam based on flag/name/sequence/cigar
# output to sam/bam/fastq/fasta

my $region = '';
$region = $filter{region} if exists $filter{region};

@ARGV = map { s/(.*\.bam)\s*$/samtools view -h $1 $region|/;$_ } @ARGV;

my %function_map = (  query               =>   \&filter_query,
                      rname               =>   \&filter_rname,
                      position            =>   \&filter_position,
                      region              =>   \&filter_region,
                      mapq                =>   \&filter_mapq,
                      cigar               =>   \&filter_cigar,
                      'mate-rname'        =>   \&filter_mate_rname,
                      'mate-position'     =>   \&filter_mate_position,
                      'mate-region'       =>   \&filter_mate_region,
                      'fragment-length'   =>   \&filter_fragment_length,
                      sequence            =>   \&filter_sequence,
                      quality             =>   \&filter_quality,
                      'quality-average'   =>   \&filter_quality_average,
                      'optional'          =>   \&filter_optional,
                      length              =>   \&filter_flag,
                   );

package Align;
use Moose;

has qname => ( is => 'rw' , isa => 'Str');
has flag => ( is => 'rw', isa => 'Str');
has rname => ( is => 'rw', isa => 'Str');
has position => ( is => 'rw', isa => 'Int');
has mapq => ( is => 'rw', isa => 'Int');
has cigar => ( is => 'rw', isa => 'Str');
has rnext => ( is => 'rw', isa => 'Str');
has pnext => ( is => 'rw', isa => 'Int');
has tlen => ( is => 'rw', isa => 'Int');
has sequence => ( is => 'rw', isa => 'Str');
has quality => ( is => 'rw', isa => 'ArrayRef[Int]');
has optional => ( is => 'rw', isa => 'ArrayRef[Str]');

sub parse_line{
  my $self = shift;
  my $line = shift;
  my @fields = qw( qname flag rname position mapq cigar rnext pnext tlen sequence);
  my $itr = 0;
  my %ref;
  my @options;
  for my $value(split /[\t\n]/, $line){
    if($itr <= $#fields){
      $ref{$fields[$itr]}=$value;
    } elsif($itr == $#fields+1){
      $ref{quality}=[ map { $_ - 64 } unpack "c*",$value ];
    } else {
      push @options, $value;
    }
    $itr++;
  }
  $ref{optional}=\@options;
  return Align->new(\%ref);
}
sub end{
  my ($read,$cigar) = @_;
  my $end = $read->position;
  while($cigar =~ /([[0-9]+)([MIDNSHPX=])/g){
    my($num,$operation)=($1,$2);
    if($operation =~ /[MDN=X]/){
      $end+=$num;
    }
  }
  return $end;
}
__PACKAGE__->meta->make_immutable;

no Moose;

package main;

use JimBar;

my $bar = JimBar->new();

#use Data::Dumper;
while(<>){
  if(/^@/){
    print;
  } else {
    my $align= Align->parse_line($_);
    my $count=0;
    for my $test(keys %filter){
      $count++ if &{$function_map{$test}}($align);
    }
    if($strict and $count == keys %filter or not $strict and $count){
      print;
    } 
  }
}
sub filter_query{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{query} }){
    if($read->qname =~ /$search/){
      $count++;
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_flag{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{flag} }){
    if($read->rname & $search){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_rname{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{rname} }){
    if($read->rname =~ /$search/){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_position{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{position} }){
    if($read->position <= $search and $read->end >= $search){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}

sub filter_region{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{region} }){
    my ($rname,$start,$end)=split /[:-]/, $search;
    if($read->rname eq $rname and $start <= $read->start and $end >= $read->end){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_mapq{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{mapq} }){
    if($search < $read->mapq){
      $count++; 
      return $count unless $strict;
    } 
    return $count;
  }
}

sub filter_cigar{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{cigar} }){
    if($read->rname =~ /$search/){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_mate_rname{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{'mate-rname'} }){
    if($read->rnext =~ /$search/){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_mate_position{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{'mate-position'} }){
    if($read->pnext == $search){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_mate_region{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{'mate-region'} }){
    my ($rname,$start,$end)=split /[:-]/, $search;
    if($read->rnext eq $rname and $start <= $read->pnext and $end >= $read->pnext){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
#this will just be the start + pstart + length, you don't know the cigar for 
#the other end
sub filter_fragment_length{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{'fragment-length'} }){
    my($low,$high) = split/[-:,]+/,$search;
    $high = 10e10 unless $high; # set high very high if not defined
    my $length = abs($read->tlen); 
    if($length >= $low and $length <= $high){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_sequence{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{sequence} }){
    if($read->sequence =~ /$search/){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_quality{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{quality} }){
    my($low,$high,$cutoff) = split/[-:,]+/,$search;
    $high = 100 unless $high; # set high very high if not defined
    $cutoff = 1 unless $cutoff;
    my $match=0;
    for my $qual(@{ $read->quality }){
      if($qual >= $low and $qual <= $high){
        $match++; 
      }
    }
    use Data::Dumper;
    $count++ if((is_float($cutoff) and $cutoff <= $match/@{$read->quality}) or $match >= $cutoff);
    return $count unless $strict;
  }
  return $count;
}
sub filter_quality_average{
  my $read = shift;
  my $count=0;
  #print STDERR Dumper($read->quality,sum(@{$read->quality}));
  my $average = sum(@{$read->quality})/scalar @{$read->quality};
  for my $search(@{ $filter{'quality-average'} }){
    my($low,$high) = split/[-:,]+/,$search;
    $high = 100 unless $high; # set high very high if not defined
    if($average >= $low and $average <= $high){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_optional{
  my $read = shift;
  my $count=0;
  for my $search(@{ $filter{optional} }){
    if($read->optional =~ /$search/){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
sub filter_length{
  my $read = shift;
  my $count=0;
  my $length = $read->end-$read->start;
  for my $search(@{ $filter{'quality-average'} }){
    my($low,$high) = split/[-:,]+/,$search;
    if($length >= $low and $length <= $high){
      $count++; 
      return $count unless $strict;
    }
  }
  return $count;
}
# regex from http://perldoc.perl.org/perlfaq4.html#How-do-I-determine-whether-a-scalar-is-a-number%2fwhole%2finteger%2ffloat%3f
sub is_float{
  return $_[0] =~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

filter_align.pl - filters alignments from a bam or sam file

=head1 SYNOPSIS

filter_align.pl [options] [file ...]

Options:
      -flag
      -fragment-length
      -length
      -mapq
      -position
      -region
      -reference
      -position
      -quality
      -quality-average
      -query
      -region
      -reference
      -sequence
      -strict
      -help
      -man 

=head1 OPTIONS

=over 8

=item B<-strict>

All searches must be completely true

=item B<-query>

Search for a regex matching the query string (read name)

=item B<-flag>

Search the bitwise flag for the given bit, can be a normal integer (ex. 16), an octal (ex. 020),
a hexadecimal (ex. 0x10), or binary (ex. 0b10000) number

  Bit      Description
  0x1      template having multiple segments in sequencing
  0x2      each segment properly aligned according to the aligner
  0x4      segment unmapped
  0x8      next segment in the template unmapped
  0x10     SEQ being reverse complemented
  0x20     SEQ of the next segment in the template being reversed
  0x40     the 0x80 the last segment in the template
  0x100    secondary alignment
  0x200    not passing quality controls
  0x400    PCR or optical duplicat

=item B<-rname -chromosome -reference>

Search for the reference where the read is mapped

=item B<-length>

search for read lengths, if given one number, all reads with lengths 
greater than the number are returned, if given two numbers seperated 
by a [-:,] all reads with length in between the numbers are returned

=item B<-position>

Search for the position where the read is mapped

=item B<-region>

Search for the reference and position in the form

ref:start-end

ex. (chr12:12345-54321)

=item B<-mapq>

search for mapping qualities, if given one number, all reads with mapping 
qualities greater than the number are returned, if given two numbers seperated 
by a [-:,] all reads with qualites in between the numbers are returned

=item B<[-:,]cigar>

Search the cigar string with the regex given

=item B<-mate-rname -mate-chromosme -mate-reference>

Search for the reference where the mate is mapped

=item B<-mate-position>

Search for the position where the mate is mapped

=item B<-mate-region>

Search for the reference and position of the mate in the form

ref:start-end

ex. (chr12:12345-54321)

=item B<-fragment-length>

search for fragment length (abs(start-(mate_end))), if given one number, all 
reads with fragment lengths greater than the number are returned, if given two 
seperated by a [-:,] all read pairs with fragment lengths in between the 
numbers are returned

=item B<-sequence>

Search the sequence with a regex

=item B<-quality>

search for quality, if given one number, all reads with qualities greater than 
the number are returned, if given two numbers seperated by a [-:,] all reads 
with qualites in between the numbers are returned.  If given three numbers, at 
least the third number of qualites per must match

=item B<-quality-average>

search for average quality, if given one number, all reads with average 
qualities greater than the number are returned, if given two numbers seperated 
by a [-:,] all reads with average qualites in between the numbers are returned.  

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<filter_align.pl> filters alignments from a bam or sam file

=cut

