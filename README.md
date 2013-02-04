# Fasta Utilities #

A collection of scripts developed to interact with fasta, fastq and sam files.  
All the scripts use the ReadFastx module I created , which reads either a fasta 
or fastq file by record.  It also uses the FileBar module, which gives 
a terminal progress bar on a file as it is processed.  ReadSam is the sam 
equivelent.

## Conversion ##
- *2big.pl*                 -  takes a bed, sam, or wiggle file and creates a big 
  version of it to upload to ucsc
- *fastq2fasta.pl*          -  converts fastq to fasta
- *sam2fastq.pl*            -  Converts a sam format to fastq format
- *mate_pair2paired_end.pl* -  converts mate pair reads to paired end orientation

## Reformatting ##
- *fix_headers.pl*       -  fixes the fastq header by removing spaces and 
  optionally appending a suffix
- *remap_file.pl*        -  takes a file with tab delimited mappings and 
  substitutes each of the first terms for each of the second terms
- *standardize_names.pl* -  renames fasta files from ncbi into uscs nomenclature 
  chr##
- *unique_headers.pl*    -  reads a fasta file and ensures all of the names are 
  unique
- *wrap.pl*              -  limits fasta lines to 80 characters

## Modification ##
- *bisulfite_convert.pl*  -  bisulfite converts the sequences given to it
- *merge_records.pl*      -  merges all the input records into one record, by 
  default uses the name of the first record, but can be changed with -name
- *reverse_complement.pl* -  takes sequences and reverse complements them
- *trim_fasta.pl*         -  trims a fastx file to x bp
- *pairs_sorted.pl*       -  takes two files of reads sorted by header, and 
  outputs two files containing those reads which have pairs
- *pairs_unsorted.pl*     -  gets the pairs of the files in the first file from 
  the second file, pairs are matched by header name
- *regex_fasta.pl*        -  applies the given regex to the fasta headers or 
  sequence
- *remove_ambiguous.pl*   -  removes ambiguity codes from fasta files
- *splice.pl*             -  splice a fasta file given a gff file
- *split_fasta.pl*        -  splits a multi fasta file into multiple files, can 
  split in different ways
- *subset_fasta.pl*       -  subsets a fasta file
- *trans_fasta.pl*        -  translate a fasta cDNA to protein
- *generate_fasta.pl*     -  create a random fasta file
- *consensus.pl*          -  generate a consensus fasta file from a bam file

## Filtering ##
- *filter_align.pl* -  filters alignments from a bam or sam file
- *filter_reads.pl* -  filters aligned reads from a file by mapping with bowtie2
- *get_fasta.pl*    -  selects fasta records which match or don't match a pattern
- *in_list.pl*      -  reads a list of headers, and a fastx file and outputs 
  records which are in the list
- *size_select.pl*  -  returns the sequences with lengths between the values 
  specified by -low and -high
- *sort.pl*         -  sorts a fasta file using gnu sort, can sort by header, 
  sequence, length ect.

## Information ##
- *avg_coverage.pl* -  gets the average coverage per sequence from a bam file
- *lengths.pl*      -  length of each record
- *calcN.pl*        -  takes a file of fasta lengths, or a fasta or fastq file 
  directly, and calculates the nX of the file, by default N50
- *CpG_count.pl*    -  counts the number of CpGs in a fasta file
- *distances.pl*    -  get the within group bitscore distance of all the records 
  in a fasta file using blast
- *fasta_head.pl*   -  emulates unix head for fasta and fastq files
- *fasta_tail.pl*   -  emulates unix tail for fasta and fastq files
- *percent_GC.pl*   -  calculates percent GC for each fasta record in a file, as 
  well as the total GC content
- *sam_lengths.pl*  -  gets the sequence lengths from a sam file
- *size.pl*         -  gets the total size of a fasta file and the number of 
  sequences

## Bed scripts ##
- *absolute_coordinates.pl* -  takes a file with the chromosome and location and 
  a file of chromosome sizes, and converts the coordinates to an absolute scale 
  for plotting
- *bed2igv.pl*              -  converts a bed file to a igv snapshot script
- *combine_bed.pl*          -  Combine bed files
- *gff2bed.pl*              -  converts a gff file to a bed file

## Miscellaneous ##
- *align_progress.pl*    -  given the input filename and the output filename, 
  figures out the last line using tail, then greps for that header in the 
  input, and works out the percentage that way
- *blast_information.pl* -  gets sequence information from gi numbers from 
  a blast results file
- *fetch_entrez.pl*      -  Download a number of sequences from an entrez query
- *fetch_gi.pl*            -  download fasta files from NCBI and outputs a fasta file
- *fetch_sra.pl*           -  downloads the sra sequences from NCBI using aspera 
  and outputs a fastq file
- *generate_map.pl*      -  remaps fasta sequences from the first file to fasta 
  sequences from the second file, matches by hashing the sequence
- *mpileup_counts.pl*    -  parses a mpileup file and gets the base counts
- *rename_script.pl*     -  Rename a file, changing any references to the old 
  name in the file to the new name
