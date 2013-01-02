use strict;
use warnings;
use Test::More;# tests => 16;
use Test::Output;

use ReadFastx;

create_test_files();

my $fastx = ReadFastx->new("test.fasta");

my $record = $fastx->next_seq;

is($record->header, "header1", "parsing header");
is(length($record->sequence), 320, "parsing wrapped sequence");
$record->header("testing");
$record->sequence("ACGT");
is($record->header, "testing", "header accessor");
is($record->sequence, "ACGT", "sequence accessor");

$record = $fastx->next_seq;
is(length($record->sequence), 130, "parsing unwrapped sequence");

stdout_is(sub { $record->print() },">header2
CTACACTAATCACCACCTAACCCTTTCGAATCCCTCCGCCCCAAACCCAACTAGCATAAAACCCGCCATTCCAACTCCTCAGAACCCAACCTACTACCCACCCAAACCCCTAGCACCCGTGCACAGACTG\n", "print");
stdout_is(sub { $record->print(width=>80) },">header2
CTACACTAATCACCACCTAACCCTTTCGAATCCCTCCGCCCCAAACCCAACTAGCATAAAACCCGCCATTCCAACTCCTC\nAGAACCCAACCTACTACCCACCCAAACCCCTAGCACCCGTGCACAGACTG\n", "wrapped print");
stdout_is(sub { $record->print(width=>130) },">header2
CTACACTAATCACCACCTAACCCTTTCGAATCCCTCCGCCCCAAACCCAACTAGCATAAAACCCGCCATTCCAACTCCTCAGAACCCAACCTACTACCCACCCAAACCCCTAGCACCCGTGCACAGACTG\n", "wrapped exact print");
$record = $fastx->next_seq;

use Data::Dumper;
print Dumper($record);
is(length($record->sequence), 0, "parsing empty sequence");

$record = $fastx->next_seq;
is(length($record->sequence), 4, "parsing short sequence");

$record = $fastx->next_seq;

is($record->header, "header5", "short");

$fastx = ReadFastx->new("test.fastq");

$record = $fastx->next_seq;

is($record->header, "header2", "fastq header");
is(length($record->sequence), 130, "fastq sequence");
is(length($record->quality), 130, "fastq quality");


stdout_is(sub { $record->print() },
'@header2
CTACACTAATCACCACCTAACCCTTTCGAATCCCTCCGCCCCAAACCCAACTAGCATAAAACCCGCCATTCCAACTCCTCAGAACCCAACCTACTACCCACCCAAACCCCTAGCACCCGTGCACAGACTG
+header2
!I#$%&I()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZIAI^_IabcdefghijklmnopqrstuvwxyzA|A!I#$%&I()*+,-./0123456789:;<=>?@ABCDE
', "fastq print");

stdout_is(sub { $record->print(width=>80) },
'@header2
CTACACTAATCACCACCTAACCCTTTCGAATCCCTCCGCCCCAAACCCAACTAGCATAAAACCCGCCATTCCAACTCCTC
AGAACCCAACCTACTACCCACCCAAACCCCTAGCACCCGTGCACAGACTG
+header2
!I#$%&I()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZIAI^_Iabcdefghijklmnop
qrstuvwxyzA|A!I#$%&I()*+,-./0123456789:;<=>?@ABCDE
', "wrapped fastq print");

$record = $fastx->next_seq;

is(length($record->sequence), 4, "short fastq");

$record = $fastx->next_seq;

is(length($record->sequence), 320, "wrapped fastq sequence");
is(length($record->quality), 320, "wrapped fastq quality");

my $array = $record->quality_array();
$array->[0] = 10;
$record->quality_array($array);

is(substr($record->quality,0,1),chr(32+10), "modify quality");

$record->quality_at(1,11);
is(substr($record->quality,1,1),chr(32+11), "quality_at");

$fastx->close;

is($fastx->next_seq, undef, "read on close");

unlink qw(test.fasta test.fastq);
done_testing();

sub create_test_files{
  open my $fasta, '>', "test.fasta";
  print $fasta 
  ">header1
AGAAAGTATTTAATAGGAACTGTTCGTTGTGACACTATTTGTAATATTAGACGGGAATAGACAAATTTAGAAAAAGGTAA
TGTACATGTAAGGCACTGATAGAAACTTACGTGGTCAATGTTTAAGCACTGGTAAGATAAAAGATTGGCATAGACGATAA
TTGTTGTAATGTACCGTGTGTGAAAAGAATATCTTGCCGTAAGACGGAACAGGAGATAAGGTAGTTAGTAGTGATTCTCT
AAAAATGGAGTGACCCCCGGACAGTAACTCCCAAGGTAAGGTTGAAATGGAACCAAGGGGAACTAACCTAGGAGAGAAAA
>header2
CTACACTAATCACCACCTAACCCTTTCGAATCCCTCCGCCCCAAACCCAACTAGCATAAAACCCGCCATTCCAACTCCTCAGAACCCAACCTACTACCCACCCAAACCCCTAGCACCCGTGCACAGACTG
>header3

>header4
ACGT
>header5
ACGTACGT
";
  close $fasta;

  open my $fastq, '>', "test.fastq";
print $fastq q{@header2
CTACACTAATCACCACCTAACCCTTTCGAATCCCTCCGCCCCAAACCCAACTAGCATAAAACCCGCCATTCCAACTCCTCAGAACCCAACCTACTACCCACCCAAACCCCTAGCACCCGTGCACAGACTG
+header2
!I#$%&I()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZIAI^_IabcdefghijklmnopqrstuvwxyzA|A!I#$%&I()*+,-./0123456789:;<=>?@ABCDE
@short
ACGT
+
IIII
@header1
AGAAAGTATTTAATAGGAACTGTTCGTTGTGACACTATTTGTAATATTAGACGGGAATAGACAAATTTAGAAAAAGGTAI
TGTACATGTAAGGCACTGATAGAAACTTACGTGGTCAATGTTTAAGCACTGGTAAGATAAAAGATTGGCATAGACGATAI
TTGTTGTAATGTACCGTGTGTGAAAAGAATATCTTGCCGTAAGACGGAACAGGAGATAAGGTAGTTAGTAGTGATTCTCI
AAAAATGGAGTGACCCCCGGACAGTAACTCCCAAGGTAAGGTTGAAATGGAACCAAGGGGAACTAACCTAGGAGAGAAAA
+header1
!#$%&I()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZIAI^_IabcdefghijklmnopI
qrstuvwxyzI|I!I#$%&I()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMINOPQRSTUVWXYZIAI^_IaI
cdefghijklmnopqrstuvwxyzA|A!I#$%&I()*+,-./0123456789:;<=>?I@ABCDEFGHIJKLMNOPQRSI
UVWXYZIAI^_IabcdefghijklmnopqrstuvwxyzI|I!I#$%&I()*+,-./0123456789:;<=>?@ABCDEFI
@header2
CTACACTAATCACCACCTAACCCTTTCGAATCCCTCCGCCCCAAACCCAACTAGCATAAAACCCGCCATTCCAACTCCTCAGAACCCAACCTACTACCCACCCAAACCCCTAGCACCCGTGCACAGACTG
+
!I#$%&I()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZIAI^_IabcdefghijklmnopqrstuvwxyzA|A!I#$%&I()*+,-./0123456789:;<=>?@ABCDE
};
  close $fastq;
}
