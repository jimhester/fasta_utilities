#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/09/2010
# Title:CpG_count.pl
# Purpose:this script counts the number of CpGs in a fasta file
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
GetOptions('help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
@ARGV = map { s/(.*\.gz)\s*$/pigz -dc < $1|/; s/(.*\.bz2)\s*$/pbzip2 -dc < $1|/;$_ } @ARGV;
###############################################################################
# CpG_count.pl
###############################################################################
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::RealBin, '/../');
use ReadFastx;
my $fastx = ReadFastx->new();
while(my $seq = $fastx->next_seq){
    my $sequence = $seq->sequence;
    my($count) = $sequence =~ s/CG/CG/gi;
    $count = 0 unless $count;
    print $seq->header,"\t$count\n";
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

CpG_count.pl - this script counts the number of CpGs in a fasta file

=head1 SYNOPSIS

CpG_count.pl [options] [file ...]

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

B<CpG_count.pl> this script counts the number of CpGs in a fasta file

=cut

