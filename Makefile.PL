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
  "AutoLoader" => "5.73",
  "Carp" => "1.29",
  "Compress::Raw::Zlib" => "2.06",
  "Config" => "5.018002",
  "Cwd" => "3.40",
  "Data::Dumper" => "2.145",
  "DynaLoader" => "1.18",
  "Encode" => "2.49",
  "Encode::Locale" => "1.03",
  "Errno" => "1.18",
  "Exporter" => "5.68",
  "Fatal" => "2.13",
  "Fcntl" => "1.11",
  "File::Glob" => "1.20_01",
  "File::GlobMapper" => "1.000",
  "File::Path" => "2.09",
  "File::Spec" => "3.40",
  "File::Temp" => "0.23",
  "Getopt::Long" => "2.39",
  "HTTP::Config" => "6.00",
  "HTTP::Date" => "6.02",
  "IO" => "1.28",
  "Inline" => "0.53",
  "LWP" => "6.05",
  "List::MoreUtils" => "0.33",
  "List::Util" => "1.38",
  "Net::HTTP" => "6.06",
  "Pod::Escapes" => "1.04",
  "Pod::InputObjects" => "1.60",
  "Pod::Simple" => "3.28",
  "Pod::Text" => "3.17",
  "Pod::Usage" => "1.61",
  "Regexp::Common" => "2013031301",
  "Socket" => "2.009",
  "Storable" => "2.41",
  "Tie::Hash" => "1.04",
  "Tie::RefHash" => "1.39",
  "Time::Local" => "1.2300",
  "URI" => "1.60",
  "XSLoader" => "0.16",
  "base" => "2.18",
  "bytes" => "1.04",
  "constant" => "1.27",
  "if" => "0.0602",
  "overload" => "1.22",
  "Term::ProgressBar" => "0.0",
  "Readonly" => "0.0",
  },
  test => {TESTS => 'tests/*.t'}
);
