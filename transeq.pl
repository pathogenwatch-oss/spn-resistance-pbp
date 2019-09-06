#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

open(my $dna, "<", $ARGV[0]) or die "Failed to read input file.\n";
my $out = $ARGV[1];
my $frame = $ARGV[2];
$frame =~ s/-frame=//;

print STDERR "Converting $ARGV[0] to $out in frame $frame\n";

my @data = <$dna>;
close $dna;

my ($id, $aa) = &sixFrame_Translate(join("\n", @data), $frame);

open (my $out_fh, ">", $out) or die "Could not write $out\n$!";
print $out_fh ">$id\n$aa\n";
close $out_fh;

sub codon2aa {
    my ($codon) = @_;
    $codon = uc $codon;
    my (%g) = ('TCA' => 'S', 'TCC' => 'S', 'TCG' => 'S', 'TCT' => 'S', 'TTC' => 'F', 'TTT' => 'F', 'TTA' => 'L', 'TTG' => 'L', 'TAC' => 'Y', 'TAT' => 'Y', 'TAA' => '*', 'TAG' => '*', 'TGC' => 'C', 'TGT' => 'C', 'TGA' => '*', 'TGG' => 'W', 'CTA' => 'L', 'CTC' => 'L', 'CTG' => 'L', 'CTT' => 'L', 'CCA' => 'P', 'CCC' => 'P', 'CCG' => 'P', 'CCT' => 'P', 'CAC' => 'H', 'CAT' => 'H', 'CAA' => 'Q', 'CAG' => 'Q', 'CGA' => 'R', 'CGC' => 'R', 'CGG' => 'R', 'CGT' => 'R', 'ATA' => 'I', 'ATC' => 'I', 'ATT' => 'I', 'ATG' => 'M', 'ACA' => 'T', 'ACC' => 'T', 'ACG' => 'T', 'ACT' => 'T', 'AAC' => 'N', 'AAT' => 'N', 'AAA' => 'K', 'AAG' => 'K', 'AGC' => 'S', 'AGT' => 'S', 'AGA' => 'R', 'AGG' => 'R', 'GTA' => 'V', 'GTC' => 'V', 'GTG' => 'V', 'GTT' => 'V', 'GCA' => 'A', 'GCC' => 'A', 'GCG' => 'A', 'GCT' => 'A', 'GAC' => 'D', 'GAT' => 'D', 'GAA' => 'E', 'GAG' => 'E', 'GGA' => 'G', 'GGC' => 'G', 'GGG' => 'G', 'GGT' => 'G');

    if (exists $g{$codon}) {return $g{$codon};} elsif ($codon =~ /GC./i) {return 'A';} elsif ($codon =~ /GG./i) {return 'G';} elsif ($codon =~ /CC./i) {return 'P';} elsif ($codon =~ /AC./i) {return 'T';} elsif ($codon =~ /GT./i) {return 'V';} elsif ($codon =~ /CG./i) {return 'R';} elsif ($codon =~ /TC./i) {return 'S';} else {
        print STDERR "Bad codon \"$codon\"!!\n";
        return('x');
    }
}

sub sixFrame_Translate {
    my ($seq_input, $opt_f) = @_;
    (my $DNAheader, my @DNAseq) = split(/\n/, $seq_input);
    chomp $DNAheader;
    $DNAheader =~ s/\s+$//g;
    my $DNAseq = join('', @DNAseq);
    $DNAseq =~ s/\s//g;
    $DNAheader =~ s/>//g;
    $DNAseq =~ s/>//g;
    #print STDERR "\nSeq:$DNAheader\t:$DNA_length nt\n\n";
    my $DNArevSeq = reverse($DNAseq);
    $DNArevSeq =~ tr/ATGCatgc/TACGtacg/;
    #print STDERR "\nThe original DNA sequence is:\n$DNAseq \nThe reverse of DNA sequence is:\n$DNArevSeq\n";
    my @protein = '';
    my $codon1;

    if ($opt_f == 1) {
        for (my $i = 0; $i < (length($DNAseq) - 2); $i += 3) {
            $codon1 = substr($DNAseq, $i, 3);
            $protein[1] .= codon2aa($codon1);
            #$dna[1].=codon2nt($codon1);
        }
    }
    if ($opt_f == 2) {
        my $codon2;
        for (my $i = 1; $i < (length($DNAseq) - 2); $i += 3) {
            $codon2 = substr($DNAseq, $i, 3);
            $protein[2] .= codon2aa($codon2);
            #$dna[2].=codon2nt($codon2);
        }
    }
    if ($opt_f == 3) {
        my $codon3;
        for (my $i = 2; $i < (length($DNAseq) - 2); $i += 3) {
            $codon3 = substr($DNAseq, $i, 3);
            $protein[3] .= codon2aa($codon3);
            #$dna[3].=codon2nt($codon3);
        }
    }
    if ($opt_f == 4) {
        my $codon4;
        for (my $i = 0; $i < (length($DNArevSeq) - 2); $i += 3) {
            $codon4 = substr($DNArevSeq, $i, 3);
            $protein[4] .= codon2aa($codon4);
            #$dna[4].=codon2nt($codon4);
        }
    }
    if ($opt_f == 5) {
        my $codon5;
        for (my $i = 1; $i < (length($DNArevSeq) - 2); $i += 3) {
            $codon5 = substr($DNArevSeq, $i, 3);
            $protein[5] .= codon2aa($codon5);
            #$dna[5].=codon2nt($codon5);
        }
    }
    if ($opt_f == 6) {
        my $codon6;
        for (my $i = 2; $i < (length($DNArevSeq) - 2); $i += 3) {
            $codon6 = substr($DNArevSeq, $i, 3);
            $protein[6] .= codon2aa($codon6);
            #$dna[6].=codon2nt($codon6);
        }
    }
    #print STDERR "translate result\n$protein[$opt_f]\n";
    return($DNAheader, $protein[$opt_f]);
}
