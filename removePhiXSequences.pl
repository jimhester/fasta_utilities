#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:11/18/2009
# Title:removePhiXSequences.pl
# Purpose:this script runs the input reads on PhiX chromosome, and removes any that match from the reads
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $bowtie='bowtie';
my $phiX = "/data/Bowtie_Indexes/Hg18PhiX";
my $updateNum=50000;
my $processors = no_of_cores_gnu_linux();
GetOptions('processors=i' => \$processors,'updateNum=i' => \$updateNum,'phiX=s' => \$phiX,'bowtie=s' => \$bowtie, 'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# removePhiXSequences.pl
###############################################################################

use readFastx;

if($bowtie){
  my $numPhiX;
  my %sequenceToRemove = ();
  my @files = @ARGV;
  for my $file (@files) {
    my $prefix = prefix($file);
    print STDERR "Running $bowtie on $file against phiX\n";
    my $phiXfile = "$prefix.bow";
    unless( -e "$phiXfile"){
      `bowtie -p $processors $phiX $file $phiXfile`;
    }
    if ( -e $phiXfile) {
      print STDERR "Parsing reads in $phiXfile\n";
      open BOW, $phiXfile or die "$!: Could not open $phiXfile\n";
      while (<BOW>) {
        my($name,$strand,$chromosome) = split /\t/;
        ($name) = split ' ',$name;
        $sequenceToRemove{$name}++ if($chromosome eq 'PhiX');
      }
      printf STDERR "\rParsed $. lines, %.2f%% of total", tell(BOW)/-s $phiXfile if $. % $updateNum == 0;
    }
    printf STDERR "\r%d aligned reads in $file                    \n",scalar keys %sequenceToRemove;
    close BOW;
  }
  for my $fileName (@files){
    my $prefix = prefix($fileName);
    my $file = readFastx->new($fileName);
    my ($trunk, $extension) = ($fileName,"");
    if ($fileName =~ /^(.*?)\.(.*?)$/) {
      ($trunk, $extension) = ($1,$2);
    }
    my $outFile ="$trunk.noPhiX.$extension";
    open OUT, ">$outFile" or die "$!: Could not open $outFile\n";
    $file->message("printing PhiX free reads to $outFile\n");
    
    my $removed=0;
    my $total=0;
    while(my $seq = $file->next_seq){
        my($checkName) = split ' ', $seq->header;
        if(exists $sequenceToRemove{$checkName}){
          $removed++;
        } else {
          $seq->print(\*OUT);
        }
        $total++;
      $file->message( sprintf "Processed a total of %d reads, %d phiX reads removed, %.2f%% of total\n",$total,$removed, $removed/$total * 100 ) if($total % 50000 == 0);
    }
    printf STDERR "Processed a total of %d reads, %d phiX reads removed, %.2f%% of total\n",$total,$removed, $removed/$total * 100;
  }
}

#if($bowtie){
#  my $numPhiX;
#  my %sequenceToRemove = ();
#  my @files = @ARGV;
#  for my $file (@files) {
#    my $prefix = prefix($file);
#    print STDERR "Running $bowtie on $file against phiX\n";
#    my $phiXfile = "$prefix.bow";
#    unless( -e "$phiXfile"){
#      `bowtie -p $processors $phiX $file $phiXfile`;
#    }
#    if ( -e $phiXfile) {
#      print STDERR "Parsing reads in $phiXfile\n";
#      open BOW, $phiXfile or die "$!: Could not open $phiXfile\n";
#      while (<BOW>) {
#        my($name,$strand,$chromosome) = split /\t/;
#        $sequenceToRemove{$name}++ if($chromosome eq 'PhiX');
#      }
#      printf STDERR "\rParsed $. lines, %.2f%% of total", tell(BOW)/-s $phiXfile if $. % $updateNum == 0;
#    }
#    printf STDERR "\r%d aligned reads in $file                    \n",scalar keys %sequenceToRemove;
#    close BOW;
#  }
#  for my $file(@files){
#    my $prefix = prefix($file);
#    open READ, $file or die "$!: Could not open $file\n";
#    my ($trunk, $extension) = ($file,"");
#    if ($file =~ /^(.*?)\.(.*?)$/) {
#      ($trunk, $extension) = ($1,$2);
#    }
#    my $outFile ="$trunk.noPhiX.$extension";
#    open OUT, ">$outFile" or die "$!: Could not open $outFile\n";
#    print STDERR "printing PhiX free reads to $outFile\n";
#    my $firstChar = getc(READ);
#    print OUT $firstChar;
#    my $removed=0;
#    my $total=0;
#    if($firstChar eq "@"){
#      while(defined(my $name = <READ>) and
#        defined(my $sequence = <READ>) and 
#        defined(my $qName = <READ>) and
#        defined(my $quality = <READ>)){
#          if($name =~ /^[\^>@]*(.*?)[\t\n]/){
#            my($checkName) = ($1);
#            if(exists $sequenceToRemove{$checkName}){
#              $removed++;
#            } else {
#              print OUT "$name$sequence$qName$quality";
#            }
#            $total++;
#            printf STDERR "\rProcessed a total of %d reads, %d phiX reads removed, %.2f%% of total",$total,$removed, $removed/$total * 100 if($total % 50000 == 0);
#          }
#      }
#    } elsif($firstChar eq ">"){
#      $/ = $firstChar;
#      my $first = <READ>;
#      while (<READ>) {
#        chomp;
#        my ($name) = split;
#        if (exists $sequenceToRemove{$name}) {
#          $removed++;
#        } else {
#        print OUT "$firstChar$_";
#        }
#        $total++;
#        printf STDERR "\rProcessed a total of %d reads, %d phiX reads removed, %.2f%% of total",$total,$removed, $removed/$total * 100 if($total % 50000 == 0);
#      }
#      close READ;
#    }
#    printf STDERR "\rProcessed a total of %d reads, %d phiX reads removed, %.2f%% of total\n",$total,$removed, $removed/$total * 100;
#  }
#}
sub no_of_cores_gnu_linux {
    # Returns:
    #   Number of CPU cores on GNU/Linux
    #   undef if not GNU/Linux
    my $no_of_cores;
    if(-e "/proc/cpuinfo") {
        $no_of_cores = 0;
        open(IN,"cat /proc/cpuinfo|") || return undef;
        while(<IN>) {
            /^processor.*[:]/ and $no_of_cores++;
        }
        close IN;
    }
    return $no_of_cores;
}
sub prefix{
  my $name = shift;
  $name =~ s:\.[^/\.]*$::;
  return($name);
}

###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

removePhiXSequences.pl - this script runs the input reads on PhiX chromosome, and removes any that match from the reads

=head1 SYNOPSIS

removePhiXSequences.pl [options] [file ...]

Options:
      --bowtie
      --phix
      --processors
      --updateNum
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<--bowtie>

Bowtie executable to run

=item B<--updateNum>

number of lines after which to print status updates, default is 50,000

=item B<--phiX>

Location of the phiX index, default is "/data/Bowtie_Indexes/PhiX";

=item B<--processors>

Number of processors to use for the bowtie mapping, defaults to the number of processors on the server

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<removePhiXSequences.pl> this script runs the input reads on PhiX chromosome, and removes any that match from the reads

=cut

