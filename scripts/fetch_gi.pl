#!/usr/bin/env perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Created: 2013 Jan 17 10:17:28 AM
# Last Modified: 2013 Jan 17 10:45:39 AM
# Title:fetch_gi.pl
# Purpose:Gets a gi fasta file from ncbi
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man   = 0;
my $help  = 0;
my $file;
my $width = 80;
my $url =
  'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id={}&rettype=fasta&retmode=text';
my @gis;
GetOptions( 'file|f=s' => \$file, 
  'width=i' => \$width,
            'gi=s'    => \@gis,
            'help|?'  => \$help,
            man       => \$man )
  or pod2usage(2);
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
# fetch_gi.pl
###############################################################################
use Term::ProgressBar;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;

@gis = split /,/, join( ',', @gis );

push @gis, fetch_gi_from_file($file) if $file;

push @gis, @ARGV;

my $count = 0;
my $bar = Term::ProgressBar->new( { count => @gis, ETA => 'linear' } );

##TODO handle transfer fail
for my $gi (@gis) {
  my $gi_url = generate_gi_url( $gi, $url );
  my $fastx =
    ReadFastx->new("wget -qO- '$gi_url' | perl -pe 's{(?<!^)[<>]}{|}g' |");
  while ( my $seq = $fastx->next_seq ) {
    my $header = $seq->header;
    $seq->print( width => $width );
  }
  $count++;
  $bar->update($count);
}

sub generate_gi_url {
  my ( $gi, $url ) = @_;
  $url =~ s/\{\}/$gi/g;
  return $url;
}

sub fetch_gi_from_file {
  my ($file) = @_;
  my @gi_list;
  open my $in, "<", "$file" or die "$!:Could not open $file\n";
  while (<$in>) {
    chomp;
    push @gi_list, $_;
  }
  return @gi_list;
}

###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

fetch_gi.pl - Gets a gi fasta file from ncbi, you can specify them directly with -gi, or just put on the command line, if you have a file of gi use the -f switch

=head1 SYNOPSIS

fetch_gi.pl [options] [file ...]

Options:
      -file|f
      -gi
      -width
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-file|f>

file with a list of gis

=item B<-gi>

list of gis to download, can be seperated by commas

=item B<-width>

width of fasta file wrapping

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<fetch_gi.pl> Gets a gi fasta file from ncbi

=cut

