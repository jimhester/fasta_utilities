#!/usr/bin/perl

use warnings;
use strict;

while(<>){
  if(/\s0\s([0-9\>\:A-Z],*)*$|X0:i:1/){ #first is for bowtie files, second is for sam
    print $_;
  }
}
