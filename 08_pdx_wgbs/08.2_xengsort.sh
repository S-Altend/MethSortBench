#!/usr/bin/env bash
#BSUB -J xengsort_pdx[1-8]
#BSUB -n 8
#BSUB -M 80000
#BSUB -R "rusage[mem=80000]"
#BSUB -o logs/xengsort_%I.out
#BSUB -q long
#BSUB -e logs/xengsort_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

READ_DIR="${PDX_DATA_DIR}/trimmed_reads"
OUT_DIR="${PDX_DATA_DIR}/xengsort_new"
INDEX_PATH="${DATA_DIR}/xengsort/converted_index"

mkdir -p "$OUT_DIR"
mkdir -p "${REPO_DIR}/08_pdx/logs"

SAMPLES=( $(ls "${READ_DIR}"/*_r1_val_1.fq.gz | xargs -I{} basename {} _r1_val_1.fq.gz) )
SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"

READ1="${READ_DIR}/${SAMPLE}_r1_val_1.fq.gz"
READ2="${READ_DIR}/${SAMPLE}_r2_val_2.fq.gz"
SAMPLE_OUT_DIR="${OUT_DIR}/${SAMPLE}"
mkdir -p "$SAMPLE_OUT_DIR"

echo "Sample: $SAMPLE"

xengsort classify \
    --index "$INDEX_PATH" \
    --fastq "$READ1" \
    --pairs "$READ2" \
    --prefix "${SAMPLE_OUT_DIR}/${SAMPLE}" \
    --mode count \
    --threads 8
