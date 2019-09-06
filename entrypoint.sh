#!/usr/bin/env bash

cat - > /tmp/sequence.fa

./pw_wrapper.sh | grep predictor | tail -n 1 | ./to_json.pl
#./PBP-Gene_Typer.pl -f /tmp/sequence.fa -r /Users/coriny/cgps-gits/SPN-Resistance/SPN_Reference_DB/MOD_bLactam_resistance.fasta -o /tmp/ -n PW -s SPN -p 1A,2B,2X
