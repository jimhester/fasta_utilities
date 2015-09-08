# Fasta Utilities #

A collection of scripts developed to interact with FASTA, FASTQ and SAM files.
All the scripts use the ReadFastx module I wrote, which reads either a FASTA
or FASTQ file by record.  It also uses the FileBar module, which gives
a terminal progress bar on a file as it is processed.  ReadSam is the SAM
equivalent.

## Conversion ##
* 2big.pl                 -  takes a bed, SAM, or wiggle file and creates a big
  version of it to upload to ucsc
* fastq2fasta.pl          -  converts FASTQ to FASTA
* sam2fastq.pl            -  Converts a SAM format to FASTQ format
* mate_pair2paired_end.pl -  converts mate pair reads to paired end orientation

## Reformatting ##
* fix_headers.pl       -  fixes the FASTQ header by removing spaces and
  optionally appending a suffix
* remap_file.pl        -  takes a file with tab delimited mappings and
  substitutes each of the first terms for each of the second terms
* standardize_names.pl -  renames FASTA files from ncbi into uscs nomenclature
  chr##
* unique_headers.pl    -  reads a FASTA file and ensures all of the names are
  unique
* wrap.pl              -  limits FASTA lines to 80 characters

## Modification ##
* bisulfite_convert.pl  -  bisulfite converts the sequences given to it
* merge_records.pl      -  merges all the input records into one record, by
  default uses the name of the first record, but can be changed with -name
* reverse_complement.pl -  takes sequences and reverse complements them
* trim_fasta.pl         -  trims a fastx file to x bp
* pairs_sorted.pl       -  takes two files of reads sorted by header, and
  outputs two files containing those reads which have pairs
* pairs_unsorted.pl     -  gets the pairs of the files in the first file from
  the second file, pairs are matched by header name
* regex_fasta.pl        -  applies the given regex to the FASTA headers or
  sequence
* remove_ambiguous.pl   -  removes ambiguity codes from FASTA files
* splice.pl             -  splice a FASTA file given a gff file
* split_fasta.pl        -  splits a multi FASTA file into multiple files, can
  split in different ways
* subset_fasta.pl       -  subsets a FASTA file
* trans_fasta.pl        -  translate a FASTA cDNA to protein
* generate_fasta.pl     -  create a random FASTA file
* consensus.pl          -  generate a consensus FASTA file from a bam file

## Filtering ##
* filter_align.pl -  filters alignments from a bam or SAM file
* filter_reads.pl -  filters aligned reads from a file by mapping with bowtie2
* get_fasta.pl    -  selects FASTA records which match or don't match a pattern
* in_list.pl      -  reads a list of headers, and a fastx file and outputs
  records which are in the list
* size_select.pl  -  returns the sequences with lengths between the values
  specified by -low and -high
* sort.pl         -  sorts a FASTA file using gnu sort, can sort by header,
  sequence, length ect.

## Information ##
* avg_coverage.pl -  gets the average coverage per sequence from a bam file
* lengths.pl      -  length of each record
* calcN.pl        -  takes a file of FASTA lengths, or a FASTA or FASTQ file
  directly, and calculates the nX of the file, by default N50
* CpG_count.pl    -  counts the number of CpGs in a FASTA file
* distances.pl    -  get the within group bitscore distance of all the records
  in a FASTA file using blast
* fasta_head.pl   -  emulates unix head for FASTA and FASTQ files
* fasta_tail.pl   -  emulates unix tail for FASTA and FASTQ files
* percent_GC.pl   -  calculates percent GC for each FASTA record in a file, as
  well as the total GC content
* sam_lengths.pl  -  gets the sequence lengths from a SAM file
* size.pl         -  gets the total size of a FASTA file and the number of
  sequences

## Bed scripts ##
* absolute_coordinates.pl -  takes a file with the chromosome and location and
  a file of chromosome sizes, and converts the coordinates to an absolute scale
  for plotting
* bed2igv.pl              -  converts a bed file to a igv snapshot script
* combine_bed.pl          -  Combine bed files
* gff2bed.pl              -  converts a gff file to a bed file

## Miscellaneous ##
* align_progress.pl    -  given the input filename and the output filename,
  figures out the last line using tail, then greps for that header in the
  input, and works out the percentage that way
* blast_information.pl -  gets sequence information from gi numbers from
  a blast results file
* fetch_entrez.pl      -  Download a number of sequences from an entrez query
* fetch_gi.pl          -  download FASTA files from NCBI and outputs a FASTA file
* fetch_sra.pl         -  downloads the sra sequences from NCBI using aspera
  and outputs a FASTQ file
* generate_map.pl      -  remaps FASTA sequences from the first file to FASTA
  sequences from the second file, matches by hashing the sequence
* mpileup_counts.pl    -  parses a mpileup file and gets the base counts
* rename_script.pl     -  Rename a file, changing any references to the old
  name in the file to the new name

## Installation ##
Install with optional prefix, omit the prefix if you want to install
system-wide.
```bash
perl Makefile.PL PREFIX=$HOME
make
make install
```
