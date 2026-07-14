#!/usr/bin/env bash
#BSUB -J bamcmp2_sort[1-8]
#BSUB -n 16
#BSUB -M 80000
#BSUB -R "rusage[mem=80000]"
#BSUB -q long
#BSUB -o logs/bamcmp2_sort_%I.out
#BSUB -e logs/bamcmp2_sort_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

THREADS=16
TMP_DIR="${REPO_DIR}/tmp/bamcmp2_sorted"
mkdir -p "$TMP_DIR"

HUMAN_DIR="${PDX_DATA_DIR}/pipelines/methylseq_bwameth_${HUMAN_GENOME}2/bwameth/deduplicated"
MOUSE_DIR="${PDX_DATA_DIR}/pipelines/methylseq_bwameth_${MOUSE_GENOME}2/bwameth/deduplicated"

SAMPLES=( $(ls "$HUMAN_DIR"/*.markdup.sorted.bam | xargs -I{} basename {} .markdup.sorted.bam) )
SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"

echo "Name-sorting ${SAMPLE}..."

samtools sort --threads "$THREADS" -n \
    -o "${HUMAN_DIR}/${SAMPLE}.${HUMAN_GENOME}.namesorted.bam" \
    "${HUMAN_DIR}/${SAMPLE}.markdup.sorted.bam"

samtools sort --threads "$THREADS" -n \
    -o "${MOUSE_DIR}/${SAMPLE}.${MOUSE_GENOME}.namesorted.bam" \
    "${MOUSE_DIR}/${SAMPLE}.markdup.sorted.bam"

echo "Done: ${SAMPLE}"
