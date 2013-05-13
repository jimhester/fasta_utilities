package FileBar;
use Carp;
use Moose;
use MooseX::NonMoose;
use Term::ProgressBar;
use Time::HiRes qw(setitimer ITIMER_VIRTUAL);
use POSIX qw(tcgetpgrp getpgrp);
use List::MoreUtils qw(any);
use Readonly;
use Carp qw(cluck);

our $VERSION = '0.01';

extends 'Term::ProgressBar';

Readonly my $FSIZE     => 7;
Readonly my $UPDATE    => .5;
Readonly my $WAIT_TIME => 1;

has fh_out => ( is => 'ro', default => sub { \*STDERR }, isa => 'GlobRef' );
has fh_in  => ( is => 'rw', default => sub { \*ARGV },   isa => 'GlobRef' );
has files =>
  ( is => 'rw', default => sub { [@ARGV] }, isa => 'ArrayRef[Str]' );
has current_file => ( is      => 'rw',
                      default => sub {''},
                      trigger => \&_current_file_set,
                      isa     => 'Str' );
has current_file =>
  ( is => 'rw', default => '', trigger => \&_current_file_set, isa => 'Str' );

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  if ( @_ == 1 && !ref $_[0] ) {
    return $class->$orig( files => [ $_[0] ] );
  }
  else {
    return $class->$orig(@_);
  }
};

sub FOREIGNBUILDARGS {
  my ($class) = shift;
  my ($args)  = {@_};

  #use STDERR for output unless it is different
  my $fh = exists $args->{fh_out} ? $args->{fh_out} : \*STDERR;
  return { name   => _short_name( $args->{files}[0] ),
           ETA    => 'linear',
           count  => 0,#_files_size( $args->{files} ),
           remove => 1,
           fh     => $fh, };
}

sub BUILD {
  my $self = shift;

  # setup timed updates if not in the background or piping
  if ( not( $self->_is_background() or $self->_is_piping() ) ) {

    $self->{next_update}      = 0;
    $self->{total_size}       = 0;
    $self->{prev_read}        = 0;
    $self->{current_size}     = 0;
    $self->{current_file_itr} = 0;
    $self->{time}             = 0;

    $self->minor(0);
    $self->max_update_rate($UPDATE);
    $self->target(_files_size($self->files));
    $SIG{VTALRM} = sub { $self->_file_update() };
    setitimer( ITIMER_VIRTUAL, $UPDATE, $UPDATE );
  }
}

sub _files_size {
  my $files = shift;
  my $size  = 0;
  for my $file ( @{$files} ) {
    $size += ( stat($file) )[$FSIZE];
  }
  return $size;
}

sub _name_set {
  my ( $self, $new ) = @_;
  $self->name( _short_name($new) );
  return $new;
}

sub _is_background {
  open A, "</dev/tty";
  return ( exists $ENV{PARALLEL_PID}
             or \*A and tcgetpgrp( fileno(A) ) != getpgrp() );
}

sub _is_piping {
  my ($self) = @_;
  return scalar any { $_ eq '-' or $_ =~ m{\|}; } @{ $self->files };
}

sub _current_file_set {
  my ( $self, $filename ) = @_;
  my $itr =
    ( exists $self->{current_file_itr} ? $self->{current_file_itr} : 0 );
  while ( $itr < @{ $self->files } and $self->files->[$itr] ne $filename ) {
    my $size = ( stat( $self->files->[$itr] ) )[$FSIZE];
    $self->{prev_read} += $size;
    $itr++;
  }

  if ( $itr >= @{ $self->files } ) {
    return $self->done;
    cluck "$filename not in ", join( " ", @{ $self->files } );
  }
  $self->{current_read}     = ( stat( $self->files->[$itr] ) )[$FSIZE];
  $self->{current_file_itr} = $itr;
  $self->{current_file}     = $filename;
  my $short_name = _short_name($filename);
  $self->{bar_width} += length( $self->name ) - length($short_name);
  $self->{name} = $short_name;
}

override 'update' => sub {
  my ($self) = @_;
  return 0 if time - $self->start < $WAIT_TIME;
  return super();
};

sub _file_update {
  my $self = shift;
  if ( $ARGV and $self->{current_file} ne $ARGV ) {
    $self->current_file($ARGV);
  }
  else {
    if ( eof $self->{fh_in} ) {

      #if at the end of the last file finish
      if ( $self->{current_file_itr} == @{ $self->files } - 1 ) {
        return $self->done;
      }
      $self->{current_read} = $self->{current_size};
    }
    else {
      $self->{current_read} = tell $self->{fh_in};
    }
  }

  $self->{total_progress} = $self->{prev_read} + $self->{current_read};

  # if ( $self->{total_progress} >= $self->{next_update} )
  {
    $self->{next_update} = $self->update( $self->{total_progress} );
  }
  return;
}

sub _short_name {
  my $name = shift;
  return '' unless $name;
  $name =~ s{.*/}{};
  return $name;
}

sub done {
  my $self = shift;
  setitimer( ITIMER_VIRTUAL, 0, 0 );
  $self->update( $self->target );
}

sub DEMOLISH {
  my $self = shift;
  setitimer( ITIMER_VIRTUAL, 0, 0 );
  print { $self->{fh_out} } "\r", ' ' x $self->term_width, "\r"
    if $self->term_width;
}
__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

