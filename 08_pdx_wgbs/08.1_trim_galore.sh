#!/usr/bin/env bash
DATA_DIR="/omics/odcf/analysis/OE0219_projects/epiproper/public_data/achinger-kawecka_2024"

READ_DIR="${DATA_DIR}/reads"
OUT_DIR="${DATA_DIR}/trimmed_reads1"

mkdir -p "$OUT_DIR"

for READ1 in "$READ_DIR"/*_r1.fastq.gz; do
    # Derive READ2 by filename substitution
    READ2="${READ1/_r1.fastq.gz/_r2.fastq.gz}"

    # Skip if the matching R2 file does not exist
    [[ -f "$READ2" ]] || {
        echo "WARNING: Missing R2 for $READ1, skipping"
        continue
    }

    echo "Processing:"
    echo "  R1: $READ1"
    echo "  R2: $READ2"

    trim_galore \
        --paired \
        --length 40 \
        --clip_R2 6 \
        --three_prime_clip_R1 6 \
        --fastqc \
        --cores 8 \
        --gzip \
        -o "$OUT_DIR" \
        "$READ1" "$READ2"
done
    