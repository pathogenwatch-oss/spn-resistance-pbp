#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Getopt::Std;
use File::Basename;

sub checkOptions {
    my %opts;
    getopts('hi:q:o:L:I:n', \%opts);
    my ($help, $fasta, $query, $outDir, $outName, $length, $identity);

    if ($opts{h}) {
        $help = $opts{h};
        help();
    }

    if ($opts{i}) {
        $fasta = $opts{i};
        if (-e $fasta) {
            print STDERR "Assembly FASTA is: $fasta\n";
        } else {
            print STDERR "The assembly FASTA file name is not in the correct format or doesn't exist.\n";
            print STDERR "Make sure you provide the full path (/root/path/fasta_file).\n";
            help();
        }
    } else {
        print STDERR "No assembly FASTA file path argument given.\n";
        help();
    }

    if ($opts{q}) {
        $query = $opts{q};
        if (-e $query) {
            print STDERR "File containing the query reference sequence: $query\n";
        } else {
            print STDERR "The location given for the query reference sequence is not in the correct format or doesn't exist.\n";
            print STDERR "Make sure you provide the full path (/root/path/query_file).\n";
            help();
        }
    } else {
        print STDERR "The location of the query reference sequence (including full path) has not been given.\n";
        help();
    }

    $outDir = "./";
    if ($opts{o}) {
        if (-d $opts{o}) {
            $outDir = $opts{o};
            print STDERR "The output directory is: $outDir\n";
        } else {
            $outDir = $opts{o};
            mkdir $outDir;
            print STDERR "The output directory has been created: $outDir\n";
        }
    } else {
        print STDERR "The files will be output into the current directory.\n";
    }

    $length = 0.5;
    if ($opts{L}) {
        if ($opts{L} >= 0 && $opts{L} <= 1) {
            $length = $opts{L};
            print STDERR "The alignment length threshold: $length\n";
        } else {
            print STDERR "The alignment length threshold has to be a number between 0 and 1\n";
            help();
        }
    } else {
        print STDERR "The default length threshold of 0.5 will be used\n";
    }

    $identity = 50;
    if ($opts{I}) {
        if ($opts{I} >= 0 && $opts{I} <= 1) {
            $identity = $opts{I} * 100.0;
            print STDERR "The alignment identity threshold: $identity\n";
        } else {
            print STDERR "The alignment identity threshold has to be a number between 0 and 1\n";
            help();
        }
    } else {
        print STDERR "The default identity threshold of 0.5 will be used\n";
    }

    return($help, $fasta, $query, $outDir, $length, $identity);
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

sub extractFastaRecordByID {
    my ($lookup, $reference) = @_;
    open my $fh, "<", $reference or die $!;
    #print STDERR "lookup: $lookup\n";
    local $/ = "\n>"; # read by FASTA record

    my $output;
    while (my $seq = <$fh>) {
        chomp $seq;
        #print STDERR "while seq:\n$seq\n";
        my ($id) = $seq =~ /^>*(\S+)/; # parse ID as first word in FASTA header
        if ($id eq $lookup) {
            $seq =~ s/^>*.+\n//; # remove FASTA header
            #$seq =~ s/\n//g;  # remove endlines
            #print STDERR ">$id\n";
            #print STDERR "$seq\n";
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
    my ($assembly_fasta, $query_length, $pid_threshold, $coverage_threshold) = @_;
    print STDERR "Extracting target fragment\n";

    system("blastn -db TEMP_nucl_blast_db -query TEMP_query_sequence.fna -outfmt 6 -word_size 7 -out TEMP_assembly-vs-query_blast.txt");
    my $bestHit = `cat TEMP_assembly-vs-query_blast.txt | sort -k12,12 -nr -k3,3 -k4,4 | head -n 1`;
    my @bestArray = split('\t', $bestHit);
    my $best_name = $bestArray[1];
    my $best_identity = $bestArray[2];
    my $best_len = $bestArray[3];
    my $frag_length = $best_len / $query_length;
    #print STDERR "best hit: $bestHit || $frag_length\n";

    print STDERR "\ncontig name of best hit against the query sequence: $best_name\n";
    print STDERR "% identity of best hit against the query sequence: $best_identity\n";
    print STDERR "length of best hit against the query sequence: $best_len\n";

    if ($best_identity >= $pid_threshold && $frag_length >= $coverage_threshold) {
        if ($bestArray[8] < $bestArray[9]) {
            #my $frag_start = $bestArray[8] - 1;
            my $blast_endDiff = $query_length - $bestArray[7];
            my $frag_start = $bestArray[8] - $bestArray[6];
            my $frag_end = $blast_endDiff + $bestArray[9];
            open(my $fh, '>', 'TEMP_frwd_extract.bed') or die "Could not open file 'TEMP_frwd_extract.bed' $!";
            print $fh "$best_name\t$frag_start\t$frag_end\n";
            close $fh;
            my $extract_frag_frwd = `bedtools getfasta -fi $assembly_fasta -bed TEMP_frwd_extract.bed -fo stdout`;

            return $extract_frag_frwd;
        } elsif ($bestArray[9] < $bestArray[8]) {
            #my $query_extract = $query_strt - 500;
            my $blast_endDiff = $query_length - $bestArray[7];
            my $frag_start = $bestArray[8] + $bestArray[6] - 1;
            my $frag_end = $bestArray[9] - $blast_endDiff - 1;
            open(my $fh, '>', 'TEMP_rev_extract.bed');
            print $fh "$best_name\t$frag_end\t$frag_start\n";
            close $fh;

            my $extract_frag_rev = `bedtools getfasta -tab -fi $assembly_fasta -bed TEMP_rev_extract.bed -fo stdout`;
            if ($extract_frag_rev) {
                #print STDERR "extract frag is:\n$extract_frag_rev\n";
                my @rev_frag_array = split('\t', $extract_frag_rev);
                my $rev_comp_frag = reverse($rev_frag_array[1]);
                $rev_comp_frag =~ tr/ATGCatgc/TACGtacg/;
                return ">$rev_frag_array[0]$rev_comp_frag";
            } else {
                return '';
            }
        }
    } else {
        return '';
    }

}

my ($help, $fasta, $query, $outDir, $length_threshold, $identity_threshold) = checkOptions(@ARGV);

chdir "$outDir";

print STDERR "Create a blast database using the assembled contigs.\n";
system("makeblastdb -in $fasta -dbtype nucl -out TEMP_nucl_blast_db");

###Blast each sequence given in the query fasta file against the blast nucleotide database.###
my @query_names = @{&extractIDsFromFasta($query)};
print STDERR "BLAST each sequence in $query against the assembly: @query_names";

foreach my $query_name (@query_names) {

    my $extract_out = "EXTRACT_" . $query_name . "_target.fasta";
    my $error_out = "ERROR_" . $query_name . "_target.fasta";

    open(my $exOUT, ">", $extract_out) or die "Could not open file $extract_out: $!";

    my $query_seq = extractFastaRecordByID($query_name, $query);
    my $query_length = fasta_seq_length($query_seq);

    # Write temporary query sequence file
    open ( my $qOUT, ">", 'TEMP_query_sequence.fna' ) or die "Could not open file TEMP_query_sequence.fna: $!";
    print $qOUT $query_seq;
    close $qOUT;

    my $fragment_fasta_str = extractTargetFragment($fasta, $query_length, $identity_threshold, $length_threshold);

    if (defined $fragment_fasta_str && 0 != length($fragment_fasta_str)) {
        print $exOUT "$fragment_fasta_str";
    } else {
        open(my $errOUT, ">>", $error_out) or die "Could not open file $error_out: $!";
        print $errOUT "Frag Extraction: The best blast hit for $query_name fragment didn't meet minimum criteria of length and identity to call a true match\n\n";
        close $errOUT;
    }
    close $exOUT;
    print STDERR "Wrote $extract_out";
}
