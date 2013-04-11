#!/usr/bin/env perl

use Regexp::Common qw /number/;
use Number::Format qw(:subs);

my $re = $RE{num}{real}{-keep};
while(<>){
  s{$re}{
    format_number($1);
  }eg;
  print;
}
