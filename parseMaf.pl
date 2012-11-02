#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:02/13/2012
# Title:parseMaf.pl
# Purpose:this script parses a maf file and outups alignments which match the
# specified criteria
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my @include;
my @exclude;
my %include;
my %exclude;
my $score=-10000000000;
my $strict;
my $sort;
my $size=-1;
my $outFmt = "maf";
GetOptions('size=i' => \$size, 'sort' => \$sort, 'strict' => \$strict,'score=f' => \$score, 'include=s' =>
\@include, 'exclude=s' => \@exclude,'format|out=s' => \$outFmt, 'help|?' =>
\$help, man => \$man) or pod2usage(2); 

for my $range (map { split /,/ } @include){
  my($org,$seq,$start,$end) = split /[:-]/, $range;
  push @{ $include{$org} }, { chr => $seq, start => $start, end => $end };
}
for my $range (map { split /,/} @exclude){
  my($org,$seq,$start,$end) = split /[:-]/, $range;
  push @{ $exclude{$org} }, { chr => $seq, start => $start, end => $end };
}
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

###############################################################################
# Automatically extract compressed files
###############################################################################
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# parseMaf.pl
###############################################################################
use Bio::AlignIO;

my @alns;

my $alignio = Bio::AlignIO->new(-fh => \*ARGV, -format => 'maf');
my $out = Bio::AlignIO->new(-fh => \*STDOUT, -format => $outFmt);

my $included=1;
my $excluded=0;
my $count=0;
while(my $aln = $alignio->next_aln()){
  $included=0 if %include;
  $excluded=0 if %exclude;
  print STDERR "\r$count" if $count % 1000 == 0;
  $count++;
  next if $aln->score < $score;
  next if $aln->length < $size;
  for my $seq ($aln->each_seq()){
    my($org,$chr) = split /\./, $seq->id;
    if(exists $exclude{$org} and overlap($exclude{$org},$seq,$chr)){
      $excluded++;
      last;
    }
    if(exists $include{$org} and overlap($include{$org},$seq,$chr)){
      $included++;
    }
  }
  if($included and not $excluded){
    if(!$strict or $included == keys %include){
      if($sort){
        push @alns, $aln;
      } else {
        $out->write_aln($aln);
      }
    }
  }
}
print STDERR "\r                                                                                \r";
if($sort){
  for my $aln (sort { $b->score <=> $a->score } @alns){
    $out->write_aln($aln);
  }
}
if($out->isa("Bio::AlignIO::maf")){
  $out->end;
}
exit;
sub overlap{
  my $first = shift;
  my $seq = shift;
  my $chr = shift;
  return 1 if not defined $first or not defined $first->[0]->{chr};
  for my $range(@{ $first }){
    if($range->{chr} eq $chr){
      my $overlap = min($range->{end},$seq->end()) - max($range->{start},$seq->start());
      return $overlap if $overlap > 0;
    }
  }
  return 0;
}
sub min{
  if($_[0] < $_[1]){
    return $_[0];
  }
  return $_[1];
}
sub max{
  if($_[0] < $_[1]){
    return $_[1];
  } 
  return $_[0];
} 
#package readMaf;
#
#sub new {
#  my $class = shift;
#  my $self = {};
#  bless $self, $class;
#  $self->{name} = shift;
#  $self->__initialize__();
#  return $self;
#}
#sub __initialize__{
#  my $self = shift;
#  if($self->{name}){
#    unless (ref $self->{name} =~ /GLOB/) {
#      $self->{filename} = $self->{name};
#      open $self->{fh}, $self->{filename} or die "$! Could not open ".$self->{filename}."\n";
#      $self->{bar} = JimBar->new($self->{fh},$self->{filename});
#    } else {
#      $self->{fh} = $self->{name};
#    }
#  } else {
#    $self->{bar} = JimBar->new();
#    $self->{fh} = *ARGV;
#  }
#  
#  my $first = getc $self->{fh};
#  my $second = getc $self->{fh};
#  if($first eq "#" and $second eq "#"){
#    $self->{header} = readline $self->{fh};
#    my $next_line = shift;
#    while($next_line =~ /^#/){
#      $self->{comments} .= $next_line;
#      $next_line = shift;
#    }
#    $self->{next_rec} = $next_line unless $next_line =~ /^$/;
#    $self->_readRec_();
#  } else {
#    die $ARGV . " is not a maf file, first line must start with ##\n";
#  }
#}
#sub _readRec_{
#  my $self = shift;
#  my $line = readline $self->{fh};
#  while($line =~ /^$/){
#    $self->{next_rec} .= $line;
#    $line = readline $self->{fh};
#  }
#}
#sub next_aln{
#  my $self = shift;
#  _readRec_() unless $self->{next_rec};
#  my $rec = mafAlign->new();
#for my $line(split /\n/, $self->{next_rec}){
#  if($line =~ /^a score=(\d+)/){
#    $rec->score = $1;
#  } elsif($line =~ /^s\s(\w+).(\w+)\s(\d+)\s(\d+)\s([+-])\s\d+\s\(w+)/){
#    push $rec->alignments-
#  }
#  }
#}
#}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

parseMaf.pl - this script parses a maf file and outups alignments which match the specified criteria

=head1 SYNOPSIS

parseMaf.pl [options] [file ...]

Options:
      -include
      -exclude
      -format
      -score
      -strict
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-include>

ranges to include in the format organism:chromosome:start-end, if start-end are
not given all alignments on that chromosome are included, if only the organism
is included then all alignments with that organism are included

=item B<-exclude>

ranges to exclude in the format organism:chromosome:start-end, if start-end are
not given all alignments on that chromosome are excluded, if only the organism
is excluded then all alignments with that organism are excluded

=item B<-format>

the output format to write in, fasta, phlip, nexus are some examples

=item B<-score>

a score theshold above which alignments are outputted

=item B<-strict>

whether the include and exclude arguments are strict, ie they must all be satisfied

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<parseMaf.pl> this script parses a maf file and outups alignments which match the specified criteria

=cut

