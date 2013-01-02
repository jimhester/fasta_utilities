# Fasta Utilities #

A collection of scripts developed to interact with fasta, fastq and sam files.  
All the scripts use the ReadFastx module I created , which reads either a fasta 
or fastq file by record.  It also uses the FileBar module, which gives 
a terminal progress bar on a file as it is processed.  ReadSam is the sam 
equivelent.

A brief description of the scripts.

## Conversion ##
* fastq2fasta.pl          -  converts fastq to fasta
* sam2fastq.pl            -  Converts a sam format to fastq format
* mate_pair2paired_end.pl -  converts mate pair reads to paired end orientation
* to_big.pl               -  takes a bed, sam, or wiggle file and creates a big 
  version of it to upload to ucsc

## Reformatting ##
* fix_headers.pl       -  fixes the fastq header by removing spaces and 
  optionally appending a suffix
* remap_file.pl        -  takes a file with tab delimited mappings and 
  substitutes each of the first terms for each of the second terms
* standardize_names.pl -  renames fasta files from ncbi into uscs nomenclature 
  chr##
* unique_headers.pl    -  reads a fasta file and ensures all of the names are 
  unique
* wrap.pl              -  limits fasta lines to 80 characters

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
* remove_ambiguous.pl   -  removes ambiguity codes from fasta files
* split_fasta.pl        -  splits a multi fasta file into multiple files, can 
  split in different ways
* subset_fasta.pl       -  subsets a fasta file

## Filtering ##
* filter_align.pl -  filters alignments from a bam or sam file
* in_list.pl      -  reads a list of headers, and a fastx file and outputs 
  records which are in the list
* size_select.pl  -  returns the sequences with lengths between the values 
  specified by -low and -high

## Information ##
* avg_coverage.pl -  gets the average coverage per sequence from a bam file
* lengths.pl      -  length of each record
* calcN.pl        -  takes a file of fasta lengths, or a fasta or fastq file 
  directly, and calculates the nX of the file, by default N50
* CpG_count.pl    -  counts the number of CpGs in a fasta file
* fasta_head.pl   -  emulates unix head for fasta and fastq files
* fasta_tail.pl   -  emulates unix tail for fasta and fastq files
* percent_GC.pl   -  calculates percent GC for each fasta record in a file, as 
  well as the total GC content
* sam_lengths.pl  -  gets the sequence lengths from a sam file
* total_bp.pl     -  calculates the total number of bases in a file

## Bed scripts ##
* absolute_coordinates.pl -  takes a file with the chromosome and location and 
  a file of chromosome sizes, and converts the coordinates to an absolute scale 
  for plotting
* combine_bed.pl          -  Combine bed files

## Miscellaneous ##
* align_progress.pl    -  given the input filename and the output filename, 
  figures out the last line using tail, then greps for that header in the 
  input, and works out the percentage that way
* blast_information.pl -  gets sequence information from gi numbers from 
  a blast results file
* entrez_fetch.pl      -  Download a number of sequences from an entrez query
* generate_map.pl      -  remaps fasta sequences from the first file to fasta 
  sequences from the second file, matches by hashing the sequence
* get_sra.pl           -  downloads the sra sequences from NCBI using aspera 
  and outputs a fastq file
* mpileup_counts.pl    -  parses a mpileup file and gets the base counts
* rename_script.pl     -  Rename a file, changing any references to the old 
  name in the file to the new name
