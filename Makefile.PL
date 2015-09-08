#!/usr/bin/env perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Find;

my @exe_files = glob("scripts/*.pl");

WriteMakefile(
  NAME            => 'fasta_utilities',
  VERSION    => '0.25',
  EXE_FILES => \@exe_files,
  test => {TESTS => 'tests/*.t'}
);
