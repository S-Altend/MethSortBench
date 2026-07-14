#!/usr/bin/env bash
#BSUB -J "xengsort[1-8]"
#BSUB -q verylong
#BSUB -n 8
#BSUB -R "rusage[mem=60000]"
#BSUB -o logs/xengsort_%I.out
#BSUB -e logs/xengsort_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

IDX=$(( LSB_JOBINDEX - 1 ))
PAIR_IDX=$(( IDX / 2 ))
DEPTH_IDX=$(( IDX % 2 ))
read -r HUMAN_SAMPLE MOUSE_SAMPLE <<< "${SAMPLE_PAIRS[$PAIR_IDX]}"
TOTAL_COUNT="${TOTAL_COUNTS[$DEPTH_IDX]}"
SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"

INDEX_PATH="${DATA_DIR}/xengsort/converted_index"
OUT_DIR="${DATA_DIR}/xengsort"
THREADS=8

for MIXTURE in "${MIXTURES[@]}"; do
    MIXTURE_DIR="${DATA_DIR}/mixtures/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
    for REPLICATE in "${REPLICATES[@]}"; do
        PREFIX="mixed_${REPLICATE}"
        OUT_PREFIX="${OUT_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}/${PREFIX}"
        mkdir -p "$(dirname "$OUT_PREFIX")"
        xengsort classify \
            --index "$INDEX_PATH" \
            --fastq "${MIXTURE_DIR}/${PREFIX}_r1.fastq.gz" \
            --pairs "${MIXTURE_DIR}/${PREFIX}_r2.fastq.gz" \
            --prefix "$OUT_PREFIX" \
            --mode count \
            --threads "$THREADS"
    done
done
