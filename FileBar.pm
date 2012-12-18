use namespace::autoclean;

package FileBar;
use Moose;
use MooseX::NonMoose;
use Moose::Util;
use Term::ProgressBar;
use Time::HiRes qw(setitimer ITIMER_VIRTUAL);
use POSIX qw(tcgetpgrp getpgrp);
use List::MoreUtils qw(any);
use Readonly;
use IO::Interactive qw(is_interactive);
use Carp;

extends 'Term::ProgressBar';

Readonly my $FSIZE  => 7;
Readonly my $UPDATE => .25;

has fh_in => (is => 'rw', default => sub { \*ARGV }, isa => 'GlobRef');
has files => (is => 'rw', default => sub { [@ARGV] }, isa => 'ArrayRef[Str]');
has current_file => (is => 'rw', trigger => \&_current_file_set, isa => 'Str');
has name         => (is => 'rw', trigger => \&_name_set,         isa => 'Str');

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

sub FOREIGNBUILDARGS {
  my $class = shift;
  return {name => '', ETA => 'linear', count => 1, remove => 1};
}

sub BUILD {
  my $self = shift;
  if (is_interactive()
      and not($self->_is_background()
              or any { $_ =~ m{[-|]}; } @{$self->files}))
  {

    # setup timed updates if interactive and not in the background or piping
    my $size = 0;
    for my $file (@{$self->files}) {
      $size += (stat($file))[$FSIZE];
    }
    $self->target($size);
    $self->{prev_size}        = 0;
    $self->{current_size}     = 0;
    $self->{current_position} = 0;
    $self->{current_file}     = '';
    $self->{next_update}      = 0;
    $self->minor(0);
    $self->max_update_rate($UPDATE);
    $SIG{VTALRM} = sub { $self->_file_update() };
    setitimer(ITIMER_VIRTUAL, $UPDATE, $UPDATE);
  }
}

sub _name_set {
  my ($self, $new) = @_;
}

sub _is_background {
  open A, "</dev/tty";
  return (exists $ENV{PARALLEL_PID} or \*A and tcgetpgrp(fileno(A)) != getpgrp());
}

sub _current_file_set {
  my ($self, $file_name) = @_;
  my $itr = exists $self->{current_position} ? $self->{current_position} : 0;
  while ($itr < @{$self->files} and $self->files->[$itr] ne $file_name) {
    my $size = (stat($self->files->[$itr]))[$FSIZE];
    $self->{prev_size} += $size;
    $itr++;
  }
  croak "$file_name not in ", join(" ", @{$self->files}), " something is very wrong!"
    if $itr >= @{$self->files};
  $self->{current_position} = $itr;
  $self->{current_size} =
    (stat($self->files->[$self->{current_position}]));
  $self->{current_file} = $file_name;
  my $short_name = _short_name($file_name);
  $self->{bar_width} += length($self->name) - length($short_name);
  $self->name($short_name);
}

sub _file_update {
  my $self = shift;

  #print Dumper($ARGV, $self);
  return $self->done
    if $self->{current_position} >= @{$self->files} and eof $self->{fh_in};
  if ($ARGV and $self->{current_file} ne $ARGV) {
    $self->current_file($ARGV);
  }
  $self->{current_progress} = tell $self->{fh_in} unless eof $self->{fh_in};
  $self->{total_progress}   = $self->{prev_size} + $self->{current_progress};
  $self->{next_update}      = $self->update($self->{total_progress})
    if $self->{total_progress} >= $self->{next_update};
  return;
}

sub _short_name {
  my $name = shift;
  $name =~ s{.*/}{};
  return $name;
}

sub done {
  my $self = shift;
  setitimer(ITIMER_VIRTUAL, 0, 0);
  $self->update($self->target);
}

sub DEMOLISH {
  my $self = shift;
  setitimer(ITIMER_VIRTUAL, 0, 0);
  $self->update($self->target); 
}
__PACKAGE__->meta->make_immutable;
1;
