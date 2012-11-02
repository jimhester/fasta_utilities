#!/usr/bin/perl
use warnings;
use strict;
###############################################################################
# By Jim Hester
# Date:03/16/2011
# Title:alignProgress.pl
# Purpose:given the input filename and the output filename, figures out the last line using tail, then greps for that header in the input, and works out the percentage that way
###############################################################################

###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my $man = 0;
my $help = 0;
my $estimateCompletion;
my $waitTime = 1;
my $observations = 10;
GetOptions('observations=i' => \$observations,'eta|ec|estimateCompletion' => \$estimateCompletion,'wait=f' => \$waitTime,'help|?' => \$help, man => \$man) or pod2usage(2);
pod2usage(2) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
###############################################################################
# alignProgress.pl
###############################################################################
use Time::HiRes qw(time);

my $inputFile = shift;
my $outputFile = shift;

my ($location1,$firstTime)=(0,0);
  
while($location1 == 0){
  ($location1,$firstTime) = getLocation($inputFile,$outputFile);
  sleep($waitTime);
}

my $size = -s $inputFile;

printf "%.2f%%\n",$location1/$size*100;

if($estimateCompletion){
  use POSIX                   qw( strftime );
  use constant MINUTE => 60;
  use constant HOUR   => 60 * MINUTE;
  use constant DAY    => 24 * HOUR;

  # The point past which to give ETA of just date, rather than time
  use constant ETA_DATE_CUTOFF => 3 * DAY;
  # The point past which to give ETA of time, rather time left
  use constant ETA_TIME_CUTOFF => 10 * MINUTE;
  # The ratio prior to which to not dare any estimates
  use constant PREDICT_RATIO => 0.01;
  my $leftSum = 0;
  my($location2,$nextTime) = (0,0);
  for(1..$observations){
    sleep($waitTime);
    ($location2,$nextTime) = (0,0);
    while($location2 == 0 or $location2 == $location1){
      ($location2,$nextTime) = getLocation($inputFile,$outputFile);
      sleep($waitTime);
    }
    my $percentProgress = ($location2 - $location1)/$size;
    my $percentRemaining = 1-($location2/$size);
    my $timeTaken = ($nextTime - $firstTime);
    if($percentRemaining < .001){
      print "Alignment Done"
    }
    my $left = ($percentRemaining * $timeTaken)/$percentProgress;
    $location1 = $location2;
    $firstTime = $nextTime;
    $leftSum+=$left;
  }
  my $left = $leftSum/$observations;
  if ( $left  < ETA_TIME_CUTOFF ) {
    printf '%1dm%02ds Left', int($left / 60), $left % 60;
  } else {
    my $eta  = $nextTime + $left;
    my $format;
    if ( $left < DAY ) {
      $format = 'ETA  %l:%M %p';
    } elsif ( $left < ETA_DATE_CUTOFF ) {
      $format = sprintf('ETA %%l%%p+%d',$left/DAY);
    } else {
      $format = 'ETA %e%b';
    }
    print strftime($format, localtime $eta);
  }
  print "\n";
}

sub getLocation{
  my($file1,$file2) = @_;
  open IN, "tail -n 1 $file2 |";
  my($header) = split /[\t\n]/,<IN>;
  my $time = time;
  close IN;

  open OUT, "grep -b -m 1 \'$header\' $file1 |";
  my($location) = split /:/,<OUT>;
  close OUT;
  return($location,$time);
}
###############################################################################
# Help Documentation
###############################################################################
__END__

=head1 NAME

alignProgress.pl - given the input filename and the output filename, figures out the last line using tail, then greps for that header in the input, and works out the percentage that way

=head1 SYNOPSIS

alignProgress.pl [options] input output

Options:
      -eta
      -wait
      -help
      -man               for more info

=head1 OPTIONS

=over 8

=item B<-eta|ec|estimateCompletion>

Estimate the completion time by sampling the file twice, with <wait> time inbetween

=item B<-wait>

Set the amount of time between samples, default is 1 second

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<alignProgress.pl> given the input filename and the output filename, figures out the last line using tail, then greps for that header in the input, and works out the percentage that way

=cut

