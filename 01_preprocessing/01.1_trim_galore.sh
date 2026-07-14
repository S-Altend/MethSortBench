#!/usr/bin/env bash
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

READ_DIR="${DATA_DIR}/reads"
OUT_DIR="${DATA_DIR}/trimmed_reads/10bp_clip_all"
mkdir -p "$OUT_DIR"

for READ1 in "$READ_DIR"/*_r1.fastq.gz; do
    READ2="${READ1/_r1.fastq.gz/_r2.fastq.gz}"
    [[ -f "$READ2" ]] || { echo "WARNING: Missing R2 for $READ1, skipping"; continue; }

    echo "Processing: $(basename "$READ1" _r1.fastq.gz)"
    trim_galore \
        --paired \
        --fastqc \
        -q 20 \
        -o "$OUT_DIR" \
        --cores 8 \
        --clip_R1 10 \
        --clip_R2 10 \
        --three_prime_clip_R1 10 \
        --three_prime_clip_R2 10 \
        "$READ1" "$READ2"
done
