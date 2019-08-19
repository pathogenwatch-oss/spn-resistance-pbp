#!/usr/bin/env bash

temp_path=$(pwd)
export PATH=$PATH:${temp_path}

assembly=/tmp/sequence.fa
allDB_dir=/predictor/SPN_Reference_DB/
sample_out=$(pwd)


###Start Doing Stuff###
#mkdir -p ${sample_out}
#cd "$sample_out"
just_name=$(basename "$sample_out")

###Call GBS bLactam Resistances###
PBP-Gene_Typer.pl -f ${assembly} -r ${allDB_dir}/MOD_bLactam_resistance.fasta -o ${sample_out} -n ${just_name} -s SPN -p 1A,2B,2X

###Predict bLactam MIC###
scr1="${temp_path}/bLactam_MIC_Rscripts/PBP_AA_sampledir_to_MIC_20180710.sh"
bash "${scr1}" "$sample_out" "$temp_path"

###Output the emm type/MLST/drug resistance data for this sample to it's results output file###
tabl_out="TABLE_Isolate_Typing_results.txt"
printf "${just_name}\t" >> "${tabl_out}"

###PBP_ID Output###
justPBPs="NF"
sed 1d TEMP_pbpID_Results.txt | while read -r line
do
    if [[ -n "$line" ]]
    then
        justPBPs=$(echo "$line" | awk -F"\t" '{print $2}' | tr ':' '\t')
    fi
    printf "$justPBPs\t" >> "$tabl_out"
done

pbpID=$(tail -n1 "TEMP_pbpID_Results.txt" | awk -F"\t" '{print $2}')
if [[ ! "$pbpID" =~ .*NF.* ]] #&& [[ ! "$pbpID" =~ .*NEW.* ]]
then
    echo "No NF outputs for PBP Type"
    bLacTab=$(tail -n1 "BLACTAM_MIC_RF_with_SIR.txt" | tr ' ' '\t')
    printf "$bLacTab\t" >> "$tabl_out"
else
    echo "One of the PBP types has an NF"
    printf "NF\tNF\tNF\tNF\tNF\tNF\tNF\tNF\tNF\tNF\tNF\tNF\t" >> "$tabl_out"
fi

cat ${tabl_out}
