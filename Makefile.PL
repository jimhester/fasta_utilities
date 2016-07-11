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
  PREREQ_PM => {
    "Class::XSAccessor" => "0",
    "Inline" => "0",
    "LWP::Simple" => "0",
    "List::MoreUtils" => "0",
    "Moose" => "0",
    "MooseX::NonMoose" => "0",
    "Readonly" => "0",
    "Term::ProgressBar" => "0",
    "namespace::autoclean" => "0",
  },
  test => {TESTS => 'tests/*.t'}
);
