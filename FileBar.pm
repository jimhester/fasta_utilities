use namespace::autoclean;

package FileBar;
use Moose;
use Moose::Util;
use Text::ProgressBar::Bar;
use Time::HiRes qw(setitimer ITIMER_VIRTUAL);
use POSIX qw(tcgetpgrp getpgrp);
use List::MoreUtils qw(any);
use Readonly;
use Carp;

Readonly my $FSIZE => 7;

extends 'Text::ProgressBar';

has fh              => (is => 'ro', default => sub { \*ARGV }, isa     => 'GlobRef');
has files           => (is => 'ro', default => sub { [ @ARGV ] }, isa => 'ArrayRef[Str]');
has current_file    => (is => 'rw', trigger => \&_current_file, isa     => 'Str');
#has widgets => (is => 'rw's

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  if (@_ == 1 && !ref $_[0]) {
    return $class->$orig(files => [$_[0]]);
  }
  else {
    return $class->$orig(@_);
  }
};

sub BUILD {
  my $self = shift;
  unless ($self->_is_background() and any { $_ =~ m{[-|]} } @{ $self->files }) { # setup update call if in the background and not piping
    my $size=0;
    for my $file(@{ $self->files }){
      $size += (stat($file))[$FSIZE];
    }
    $self->maxval($size);
    $self->{prev_size}=0;
    $self->{current_size}=0;
    $self->{current_position}=0;
    $self->{current_file}='';
    $self->start;
    $SIG{VTALRM} = sub{ $self->_file_update() };
    setitimer(ITIMER_VIRTUAL,.05, .05);
  }
};
sub _is_background {
  open A, "</dev/tty";
  return (exists $ENV{PARALLEL_PID} or \*A and tcgetpgrp(fileno(A)) != getpgrp());
}
sub _current_file{
  my ($self,$file_name) = @_;
  my $itr = $self->{current_position};
  while($itr < @{ $self->files } and $self->files->[$itr] ne $file_name){
    my $size = (stat($self->files->[$itr]))[$FSIZE];
    $self->{prev_size} += $size;
    $itr++;
  }
  croak "$file_name not in ", join(" ",@{ $self->files }), " something is very wrong!" if $itr >= @{ $self->files };
  $self->{current_position} = $itr;
  $self->{current_size} = (stat($self->files->[$self->{current_position}]));
  for my $widget(@{ $self->widgets }){
    if ($widget->can('format_string')){
      #my $string = $widget->format_string;
      #$string =~ s{.*:}{$file_name:};
      #$widget->format_string($string);
    }
  }
}
sub _file_update{
  my $self = shift;
  $self->SUPER::finish unless $ARGV;
  if($self->{current_file} ne $ARGV){
    $self->current_file($ARGV); 
  }
  $self->{current_progress} = tell $self->{fh} unless eof $self->{fh};
  $self->{total_progress} = $self->{prev_size} + $self->{current_progress};
  #use Data::Dumper;
  #print Dumper $self;
  return($self->SUPER::update($self->{total_progress}));
};

__PACKAGE__->meta->make_immutable;
1;
