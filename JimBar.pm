package JimBar;
#use warnings;
use strict;
use Term::ProgressBar;
#use threads;
my @ISA = ("Term::ProgressBar");
use Time::HiRes qw(setitimer ITIMER_VIRTUAL);
use POSIX qw(tcgetpgrp getpgrp);

use constant DAY => 86400;
use constant HOUR => 3600;
use constant MINUTE => 60;
use constant fsSIZE => 7;

sub new {
  my $class = shift;
#     $self->{DisplayName} = __formatName__($self->{fileName});
  my $self = {};
  bless($self, $class);
  open A, "</dev/tty";
  $self->{background} = (exists $ENV{PARALLEL_PID} or tcgetpgrp(fileno(A)) != getpgrp()) if \*A;
  unless($self->{background}){
    $self->{fileSize} = 0;
    $self->{fileSoFar} = 0;
    $self->{lastSize} = 0;
    $self->{next_update} = 0;
    $self->{totalStart} = 0;
    $self->{startTime} = 0;
    $self->{displayComplete} = 0;
    $self->{DisplayName} = "";
    $self->{fileName} = "";
    $self->{progressBar} = "";
    $self->{FILE} = undef;
    if(@_){
      $self->{FILE} = shift;
      $self->{fileName} = shift;
      $self->{DisplayName} = __formatName__($self->{fileName});
      $self->__setStats__();
      $self->__makeProgressBar__();
    }
    else{
      $self->{FILE} = *ARGV;
    }
    $SIG{VTALRM} = sub{ $self->update() };
    setitimer(ITIMER_VIRTUAL,.1, .1);
  }
  return($self);
}
sub __setStats__{
  my $self = shift;
  my @fileStats = stat $self->{FILE};
  $self->{lastSize} = $self->{fileSize} = $fileStats[fsSIZE];
  $self->{next_update} = 0;
  return;
}
sub __makeProgressBar__{
  my $self = shift;
  $self->{DisplayName} = __formatName__($self->{fileName});
  $self->{progressBar} = Term::ProgressBar->new({name => $self->{DisplayName}, count=> $self->{fileSize}, ETA => 'linear',remove => 1});
  $self->{startTime} = time();
  $self->{progressBar}->max_update_rate(.1);
  return;
}
sub message{
  my $self = shift;
  return if $self->{background};
  $self->{progressBar}->message(shift);
  return;
}
sub update{
 if(defined $ARGV and $ARGV eq "-"){ #reading from a pipe
    return;
  }
  my $self = shift;
 return if $self->{background};
  my $position = tell($self->{FILE});
 if($self->{fileSize} > 0 && $position == -1){
   $self->done();
   return;
 }
 if($self->{FILE} eq "*main::ARGV" and $self->{fileName} ne $ARGV){
   return if $ARGV =~ /\|/;
   if(not $self->{fileName}){
     $self->{totalStart} = time;
     $self->{fileName} = $ARGV;
     for my $file (($ARGV,@ARGV)){
       if( -e $file){
         $self->{fileSize} += (stat($file))[fsSIZE];
       } elsif($file =~ /\|/){
       }
       else {
         die "$file does not exist\n";
       }
     }
     $self->{lastSize} = (stat($ARGV))[fsSIZE];
     if($self->{progressBar} eq ""){
       $self->__makeProgressBar__();
     }
   }
   else{
     $self->{fileSoFar} += $self->{lastSize};
     $self->{lastSize} = (stat($ARGV))[fsSIZE];
     my $elapsedTime = __formatTime__(time()-$self->{startTime});
     $self->{progressBar}->message("$self->{DisplayName} Completed in $elapsedTime");
     $self->{fileName} = $ARGV;
     $self->{startTime} = time;
     $self->__reformatName__();
     }
    }
  if($position + $self->{fileSoFar} >= $self->{next_update}){
   $self->{next_update} = $self->{progressBar}->update($position+$self->{fileSoFar});
  }
  return;
}

sub __reformatName__{
  my $self = shift;
  $self->{DisplayName} = __formatName__($self->{fileName});
  if(length($self->{progressBar}->{name}) != length($self->{DisplayName})){
    $self->{progressBar}->{bar_width} = $self->{progressBar}->{bar_width}-(length($self->{DisplayName}) - length($self->{progressBar}->{name}));
  }
  $self->{progressBar}->{name}=$self->{DisplayName};
  return;
}
sub done{ #call this after reading to finish bar
  my $self = shift;
  setitimer(ITIMER_VIRTUAL,0);
  return if $self->{background};
  $self->{next_update} = 0;#$self->{lastSize};
  if($self->{displayComplete} ==0 and $self->{progressBar}){
    my $elapsedTime = __formatTime__(time()-$self->{startTime});
    $self->{progressBar}->message("$self->{DisplayName} Completed in $elapsedTime");
    $self->{progressBar}->update($self->{fileSize});
    $self->{displayComplete} = 1;
  }
  my $time = __formatTime__(time()-$self->{totalStart});
  if( $self->{fileSize} != $self->{lastSize}){ # if more than 1 file
    print STDERR "Run Completed in $time\n";
   }
   return;
}

sub __formatTime__($){
  my $time = shift;
  my $string = "";
  if($time >= DAY){ ## more than 1 day
    my $numDays = int($time/DAY);
    if($numDays != 0){
      $string .= "$numDays Day";
      $string .="s" if $numDays > 1;
      $string .=", ";
      $time = $time - int($time/DAY)*DAY;
    }
  }
  if($time >= HOUR){ ## more than 1 hour
    my $numHours = int($time/HOUR);
    if($numHours != 0){
      $string .="$numHours Hour";
      $string .="s" if $numHours > 1;
      $string .=", ";
      $time = $time - int($time/HOUR)*HOUR;
    }
  }
  if($time >= MINUTE){ ## more than 1 minute
    my $numMinutes = int($time/MINUTE);
    if($numMinutes != 0){
      $string .="$numMinutes Minute";
      $string .="s" if $numMinutes > 1;
      $string .=", ";
      $time = $time - int($time/MINUTE)*MINUTE;
    }
  }
  $string .="$time Second";
  $string .="s" if $time != 1;
  return $string;
}

#removes any directory info from the name
sub __formatName__($){
  my $file = shift;
  if($file =~ m!.*/([\|\-\+\_\w\.]+$)!){
    $file = $1;
  }
  return $file;
}
sub DESTROY {
  my $self = shift;
  #$self->done;
  setitimer(ITIMER_VIRTUAL,0);
  return;
}
1;
