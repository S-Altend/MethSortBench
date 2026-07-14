#!/usr/bin/env bash
DATA_DIR="/omics/odcf/analysis/OE0219_projects/epiproper/public_data/guillen_2022/rrbs"

READ_DIR="${DATA_DIR}/reads"
OUT_DIR="${DATA_DIR}/trimmed_reads"

mkdir -p "$OUT_DIR"

mkdir -p "$OUT_DIR"

for READ1 in "$READ_DIR"/*_r1.fastq.gz; do

    echo "Processing:"
    echo "  R1: $READ1"

    trim_galore \
        --fastqc \
        --rrbs \
        --cores 8 \
        --gzip \
        -o "$OUT_DIR" \
        "$READ1"
done
    