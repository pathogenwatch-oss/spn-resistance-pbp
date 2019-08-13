#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Getopt::Std;
use File::Basename;

sub checkOptions {
    my %opts;
    getopts('hi:q:o:n:L:I:S:f', \%opts);
    my ($help, $fasta, $query, $outDir, $outName, $length, $identity, $frag);

    if ($opts{h}) {
        $help = $opts{h};
        help();
    }

    if ($opts{i}) {
        $fasta = $opts{i};
        if (-e $fasta) {
            print "Paired-end Read 1 is: $fasta\n";
        } else {
            print "The forward paired-end file name is not in the correct format or doesn't exist.\n";
            print "Make sure you provide the full path (/root/path/fastq_file).\n";
            help();
        }
    } else {
        print "No paired end 1 fastq file path argument given.\n";
        help();
    }

    if ($opts{q}) {
        $query = $opts{q};
        if (-e $query) {
            print "File containing the query reference sequence: $query\n";
        } else {
            print "The location given for the query reference sequence is not in the correct format or doesn't exist.\n";
            print "Make sure you provide the full path (/root/path/query_file).\n";
            help();
        }
    } else {
        print "The location of the query reference sequence (including full path) has not been given.\n";
        help();
    }

    $outDir = "./";
    if ($opts{o}) {
        if (-d $opts{o}) {
            $outDir = $opts{o};
            print "The output directory is: $outDir\n";
        } else {
            $outDir = $opts{o};
            mkdir $outDir;
            print "The output directory has been created: $outDir\n";
        }
    } else {
        print "The files will be output into the current directory.\n";
    }

    if ($opts{n}) {
        $outName = $opts{n};
        chomp($outName);
        print "The output file name prefix: $outName\n";
    } else {
        $outName = `echo "$fasta" | awk -F"/" '{print \$(NF)}' | sed 's/_S[0-9]\\+_L[0-9]\\+_R[0-9]\\+.*//g'`;
        chomp($outName);
        print "The default output file name prefix is: $outName\n";
    }

    $length = 0.5;
    if ($opts{L}) {
        if ($opts{L} >= 0 && $opts{L} <= 1) {
            $length = $opts{L};
            print "The alignment length threshold: $length\n";
        } else {
            print "The alignment length threshold has to be a number between 0 and 1\n";
            help();
        }
    } else {
        print "The default length threshold of 0.5 will be used\n";
    }

    $identity = 0.5;
    if ($opts{I}) {
        if ($opts{I} >= 0 && $opts{I} <= 1) {
            $identity = $opts{I};
            print "The alignment identity threshold: $identity\n";
        } else {
            print "The alignment identity threshold has to be a number between 0 and 1\n";
            help();
        }
    } else {
        print "The default identity threshold of 0.5 will be used\n";
    }

    if ($opts{f}) {
        $frag = 1;
        print "The extract fragment flag has been given\n";
    } else {
        $frag = 0;
    }

    #($help, $fastq1, $fastq2, $query, $outDir, $outName, $length, $identity, $gSize, $frag)
    return($help, $fasta, $query, $outDir, $outName, $length, $identity, $frag);
}

sub help {

    die <<EOF

USAGE
ExtractGene.pl -1 <forward fastq file: fastq> -2 <reverse fastq file: fastq> -q <query sequence file: file path> -o <output directory name: string> -n <output name prefix: string> -S <genome size>  [OPTIONS]

    -h   print usage
    -i   assembly FASTA filename (including full path)
    -q   query reference sequence file (including full path)
    -o   output directory
    -n   output name prefix
    -L   alignment length threshold (default is 0.5 (50%))
    -I   alignment identity threshold (default is 0.5 (50%))
    -S   organism genome size in bp (can use k/M/G suffix)
    -f   extract query fragment flag

EOF
}

# Returns the total sequence length from a (multi)-FASTA string.
sub fasta_seq_length {
    my ($seq) = @_;
    my @lines = split /\n/, $seq;
    my $final_line;
    foreach my $line (@lines) {
        chomp($line);
        if ($line =~ /^>/) {
            next;
        } else {
            $final_line .= $line;
        }
    }
    return length($final_line);
}

sub extractFastaByID {
    my ($lookup, $reference) = @_;
    open my $fh, "<", $reference or die $!;
    #print "lookup: $lookup\n";
    local $/ = "\n>"; # read by FASTA record

    my $output;
    while (my $seq = <$fh>) {
        chomp $seq;
        #print "while seq:\n$seq\n";
        my ($id) = $seq =~ /^>*(\S+)/; # parse ID as first word in FASTA header
        if ($id eq $lookup) {
            $seq =~ s/^>*.+\n//; # remove FASTA header
            #$seq =~ s/\n//g;  # remove endlines
            #print ">$id\n";
            #print "$seq\n";
            $output = ">$id\n$seq\n";
            last;
        }
    }
    return $output;
}

sub extractIDsFromFasta {
    my ($fasta_file) = @_;
    my @query_names;
    open(my $q_seq, "<", $fasta_file) or die "Could not open file '$fasta_file': $!";
    while (my $line = <$q_seq>) {
        if ($line =~ />.*/) {
            $line =~ s/>//g;
            chomp($line);
            push(@query_names, $line);
        }
    }
    close $q_seq;
    return \@query_names;
}

sub extractTargetFragment {
    my ($query_name, $query_length) = @_;
    print "Extracting target fragment\n";

    system("blastn -db TEMP_nucl_blast_db -query TEMP_query_sequence.fna -outfmt 6 -word_size 7 -out TEMP_assembly-vs-query_blast.txt");
    my $bestHit = `cat TEMP_assembly-vs-query_blast.txt | sort -k12,12 -nr -k3,3 -k4,4 | head -n 1`;
    my @bestArray = split('\t', $bestHit);
    my $best_name = $bestArray[1];
    my $best_identity = $bestArray[2];
    my $best_len = $bestArray[3];
    my $query_start = $bestArray[6];
    my $query_end = $bestArray[7];
    my $frag_length = $best_len / $query_length;
    #print "best hit: $bestHit || $frag_length\n";

    print "\ncontig name of best hit against the query sequence: $best_name\n";
    print "% identity of best hit against the query sequence: $best_identity\n";
    print "length of best hit against the query sequence: $best_len\n";

    if ($best_identity >= 50 && $frag_length >= 0.50) {
        if ($bestArray[8] < $bestArray[9]) {
            #my $frag_start = $bestArray[8] - 1;
            my $blast_endDiff = $query_length - $bestArray[7];
            my $frag_start = $bestArray[8] - $bestArray[6];
            my $frag_end = $blast_endDiff + $bestArray[9];
            open(my $fh, '>', 'TEMP_frwd_extract.bed') or die "Could not open file 'TEMP_frwd_extract.bed' $!";
            print $fh "$best_name\t$frag_start\t$frag_end\n";
            close $fh;
            my $extract_frag_frwd = `bedtools getfasta -fi ./velvet_output/contigs.fa -bed TEMP_frwd_extract.bed -fo stdout`;

            return $extract_frag_frwd;
        } elsif ($bestArray[9] < $bestArray[8]) {
            #my $query_extract = $query_strt - 500;
            my $blast_endDiff = $query_length - $bestArray[7];
            my $frag_start = $bestArray[8] + $bestArray[6] - 1;
            my $frag_end = $bestArray[9] - $blast_endDiff - 1;
            open(my $fh, '>', 'TEMP_rev_extract.bed');
            print $fh "$best_name\t$frag_end\t$frag_start\n";
            close $fh;

            my $extract_frag_rev = `bedtools getfasta -tab -fi ./velvet_output/contigs.fa -bed TEMP_rev_extract.bed -fo stdout`;
            if ($extract_frag_rev) {
                #print "extract frag is:\n$extract_frag_rev\n";
                my @rev_frag_array = split('\t', $extract_frag_rev);
                my $rev_comp_frag = reverse($rev_frag_array[1]);
                $rev_comp_frag =~ tr/ATGCatgc/TACGtacg/;
                return ">$rev_frag_array[0]\n$rev_comp_frag";
            } else {
                return '';
            }
        }
    } else {
        return '';
    }

}

my ($help, $fasta, $query, $outDir, $outName, $length, $identity, $gSize, $frag) = checkOptions(@ARGV);

chdir "$outDir";

print "Beginning Prodigal\n";
system("prodigal -c -f gff -i $fasta -a PRE_$outName.faa -o prodigal_$outName.gff -d PRE_$outName.fasta");
`cat PRE_"$outName".faa | sed 's/ # .*//g' > prodigal_"$outName".faa`;
`cat PRE_"$outName".fasta | sed 's/ # .*//g' > prodigal_"$outName".fna`;
unlink("PRE_$outName.faa");
unlink("PRE_$outName.fasta");

print "Create a blast database using the predicted genes obtained from Prodigal\n";
system("makeblastdb -in prodigal_$outName.fna -dbtype nucl -out TEMP_prod_nucl_blast_db");

print "Create a blast database using the assembled contigs.\n";
system("makeblastdb -in $fasta -dbtype nucl -out TEMP_nucl_blast_db");

###Blast each sequence given in the query fasta file against the blast nucleotide database.###
my @query_names = @{&extractIDsFromFasta($query)};

foreach my $query_name (@query_names) {

    my $extract_out = "EXTRACT_" . $query_name . "_target.fasta";
    my $error_out = "ERROR_" . $query_name . "_target.fasta";

    open(my $exOUT, ">", $extract_out) or die "Could not open file $extract_out: $!";
    print $exOUT "Complete $query_name Gene Sequence:\n";

    my $query_seq = extractFastaByID($query_name, $query);
    my $query_length = fasta_seq_length($query_seq);

    # First get the best match to the query in the Prodigal gene database
    open(my $qOUT, ">", 'TEMP_query_sequence.fna') or die "Could not open file TEMP_query_sequence.fna: $!";
    print $qOUT $query_seq;
    close $qOUT;
    system("blastn -db TEMP_prod_nucl_blast_db -query TEMP_query_sequence.fna -outfmt 6 -word_size 7 -out TEMP_prod-vs-query_blast.txt");

    ###Get the best blast hit by sorting the blast output by bit score, then % ID, then alignment length and select the first hit as the best match.###
    my $bestHit = `cat TEMP_prod-vs-query_blast.txt | sort -k12,12 -nr -k3,3 -k4,4 | head -n 1`;
    my @bestArray = split('\t', $bestHit);
    my $best_name = $bestArray[1];
    my $best_iden = $bestArray[2];
    my $best_len = $bestArray[3];
    #my $query_strt = $bestArray[6];
    #my $query_end = $bestArray[7];
    my $match_len = $length * $query_length;
    my $match_iden = $identity * 100;

    print "\nprodigal gene name of best hit against the query sequence: $best_name\n";
    print "% identity of best hit against the query sequence: $best_iden\n";
    print "length of best hit against the query sequence: $best_len\n";
    print "match length threshold: $match_len\n";

    if ($best_iden >= $match_iden && $best_len >= $match_len) {
        my $prodigal_fna = extractFastaByID($best_name, "prodigal_$outName.fna");
        my $prodigal_faa = extractFastaByID($best_name, "prodigal_$outName.faa");
        print $exOUT "$prodigal_fna\n$prodigal_faa\n\n";
    } else {
        open(my $errOUT, ">>", $error_out) or die "Could not open file $error_out: $!";
        print $errOUT "Gene Extraction: The best blast hit ($best_name) for $query_name didn't meet minimum criteria of length and identity to call a true match\n\n";
        close $errOUT;
        #next;
    }

    ###If the '-f' flag is called, then the script will also extract just the section of the target sequence that corresponds to the query fragment.###
    ###If the best blast hit didn't include the entire query fragment, then the code will calculate the expected start/end coordinates of the complete fragment
    ###and will attempt to extract the full fragment from the predicted gene sequence.###
    ###The number of non-aligning bases at each end of the matching target sequence will recorded in the header name.###
    if ($frag) {
        print $exOUT "\n$query_name Query Fragment Sequence:\n";
        my $fragment_fasta_str = extractTargetFragment($query_name, $query_length);
        if (defined $fragment_fasta_str & 0 != length($fragment_fasta_str)) {
            print $exOUT "$fragment_fasta_str";
        } else {
            open(my $errOUT, ">>", $error_out) or die "Could not open file $error_out: $!";
            print $errOUT "Frag Extraction: The best blast hit ($best_name) for $query_name fragment didn't meet minimum criteria of length and identity to call a true match\n\n";
            close $errOUT;
        }
    }
    close $exOUT;
}
chdir("..")