#!/bin/bash
shopt -s nullglob
set -euo pipefail

source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

DATA_DIR="/omics/odcf/analysis/OE0219_projects/epiproper/public_data/achinger-kawecka_2024/wgbs"
XENGSORT_DIR="${DATA_DIR}/xengsort"
METHOD="xengsort"
RESULTS_DIR="${REPO_DIR}/08_pdx/results/xengsort_wgbs"

for SAMPLE_DIR in "$XENGSORT_DIR"/*/; do
    SAMPLE=$(basename "$SAMPLE_DIR")
    OUT_DIR="${RESULTS_DIR}/${SAMPLE}"
    mkdir -p "$OUT_DIR"
    TSV_FILE="${OUT_DIR}/evaluation.tsv"
    echo "$SAMPLE"
    echo -e "Category\tReads\tSample\tMethod" > "$TSV_FILE"

    for F in "$SAMPLE_DIR"/${SAMPLE}-*.1.fq.gz; do
        FILENAME=$(basename "$F")
        CATEGORY="${FILENAME#${SAMPLE}-}"
        CATEGORY="${CATEGORY%.1.fq.gz}"
        READS=$(zcat "$F" | wc -l | awk '{print int($1/4)}')
        echo -e "${CATEGORY}\t${READS}\t${SAMPLE}\t${METHOD}" >> "$TSV_FILE"
    done
done

echo "Written to ${RESULTS_DIR}"
shopt -u nullglob