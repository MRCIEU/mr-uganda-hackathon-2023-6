#!/bin/bash

# Define constants
REF_DIR="/home/intuneadmin/MR_hackathon/reference_panel"
BIM_PREFIX="/home/intuneadmin/MR_hackathon/prs"
OUT_DIR="/home/intuneadmin/MR_hackathon/PRS"
PHI="1e-2"

# Function to run PRScsx.py for a given population
run_prscsx_for_pop() {
    local pop="$1"
    local ngwas="$2"
    local sst_file="/home/intuneadmin/MR_hackathon/GWAS_${pop}.txt"
    local out_name="PRS_${pop}"

    python PRScsx.py \
        --ref_dir=${REF_DIR} \
        --bim_prefix=${BIM_PREFIX} \
        --sst_file=${sst_file} \
        --n_gwas=${ngwas} \
        --pop=${pop} \
        --phi=${PHI} \
        --out_dir=${OUT_DIR} \
        --out_name=${out_name}
}

# Run for each population with their respective sizes
run_prscsx_for_pop "EAS" "382936" 
run_prscsx_for_pop "AFR" "198497"
run_prscsx_for_pop "SAS" "31681"
run_prscsx_for_pop "EUR" "807553"
