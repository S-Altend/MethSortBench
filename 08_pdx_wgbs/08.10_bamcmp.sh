#!/usr/bin/env bash
#BSUB -J bamcmp2[1-8]
#BSUB -n 8
#BSUB -M 150000
#BSUB -R "rusage[mem=150000]"
#BSUB -q long
#BSUB -o logs/bamcmp2_%I.out
#BSUB -e logs/bamcmp2_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

TMP_DIR="${REPO_DIR}/tmp/bamcmp2_sorted"
OUT_BASE="${REPO_DIR}/tmp/bamcmp2"

HUMAN_DIR="${PDX_DATA_DIR}/pipelines/methylseq_bwameth_${HUMAN_GENOME}2/bwameth/deduplicated"
MOUSE_DIR="${PDX_DATA_DIR}/pipelines/methylseq_bwameth_${MOUSE_GENOME}2/bwameth/deduplicated"
SAMPLES=( $(ls "$HUMAN_DIR"/*.markdup.sorted.bam | xargs -I{} basename {} .markdup.sorted.bam) )
SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"

OUTPUT_DIR="${OUT_BASE}/${SAMPLE}"
mkdir -p "$OUTPUT_DIR"

HUMAN_BAM="${HUMAN_DIR}/${SAMPLE}.${HUMAN_GENOME}.namesorted.bam"
MOUSE_BAM="${MOUSE_DIR}/${SAMPLE}.${MOUSE_GENOME}.namesorted.bam"

echo "Sample: $SAMPLE"

bamcmp -n -t 8 \
    -1 "$HUMAN_BAM" \
    -2 "$MOUSE_BAM" \
    -a "${OUTPUT_DIR}/${SAMPLE}.humanOnly.bam" \
    -A "${OUTPUT_DIR}/${SAMPLE}.humanBetter.bam" \
    -b "${OUTPUT_DIR}/${SAMPLE}.mouseOnly.bam" \
    -B "${OUTPUT_DIR}/${SAMPLE}.mouseBetter.bam" \
    -s match
