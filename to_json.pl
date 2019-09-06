#!/usr/bin/env perl
use strict;
use warnings;
use JSON;

my %data;
print STDERR "Parsing output to JSON.";

while (my $line = <>) {
    print STDERR "Input: $line\n";
    my @fields = split /\s+/, $line;
    $data{"pbp1a"} = $fields[1];
    $data{"pbp2b"} = $fields[2];
    $data{"pbp2x"} = $fields[3];
    $data{"penMic"} = $fields[4].' '.$fields[5];
    $data{"penMeningitis"} = $fields[6];
    $data{"penNonMeningitis"} = $fields[7];
    $data{"amxMic"} = $fields[8].' '.$fields[9];
    $data{"amxMeningitis"} = $fields[10];
    $data{"amxNonMeningitis"} = $fields[11];
    $data{"memMic"} = $fields[12].' '.$fields[13];
    $data{"memMeningitis"} = $fields[14];
    $data{"memNonMeningitis"} = $fields[15];
    $data{"ctxMic"} = $fields[16].' '.$fields[17];
    $data{"ctxMeningitis"} = $fields[18];
    $data{"ctxNonMeningitis"} = $fields[19];
    $data{"croMic"} = $fields[20].' '.$fields[21];
    $data{"croMeningitis"} = $fields[22];
    $data{"croNonMeningitis"} = $fields[23];
    $data{"cxmMic"} = $fields[20].' '.$fields[21];
    $data{"cxmMeningitis"} = $fields[22];
    $data{"cxmNonMeningitis"} = $fields[23];
    # $data{"ampMic"} = $fields[20].' '.$fields[21];
    # $data{"ampMeningitis"} = $fields[22];
    # $data{"ampNonMeningitis"} = $fields[23];
    # $data{"cptMic"} = $fields[20].' '.$fields[21];
    # $data{"cptMeningitis"} = $fields[22];
    # $data{"cptNonMeningitis"} = $fields[23];
    # $data{"zoxMic"} = $fields[20].' '.$fields[21];
    # $data{"zoxMeningitis"} = $fields[22];
    # $data{"zoxNonMeningitis"} = $fields[23];
    # $data{"foxMic"} = $fields[20].' '.$fields[21];
    # $data{"foxMeningitis"} = $fields[22];
    # $data{"foxNonMeningitis"} = $fields[23];
}

my $str = encode_json \%data;
print STDOUT $str;