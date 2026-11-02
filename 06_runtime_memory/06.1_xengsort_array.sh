#!/usr/bin/env bash
#BSUB -J xengsort_runmem[1-12]
#BSUB -n 8
#BSUB -R "rusage[mem=80G]"
#BSUB -q long
#BSUB -o logs/logs_newindex/xengsort_%I.out
#BSUB -e logs/logs_newindex/xengsort_%I.err

set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

# 4 sample pairs × 3 replicates = 12 jobs
# Index layout: jobs 1-3 = organoid1 reps 0-2, 4-6 = organoid2, 7-9 = organoid3, 10-12 = cellline
HUMAN_SAMPLES=("wgbs-human-pancreas-organoid1" "wgbs-human-pancreas-organoid2" "wgbs-human-pancreas-organoid3" "wgbs-human-brca-cl1")
MOUSE_SAMPLES=("wgbs-mouse-pancreas-organoid1" "wgbs-mouse-pancreas-organoid2" "wgbs-mouse-pancreas-organoid3" "wgbs-mouse-bm-hsc1")

IDX=$(( LSB_JOBINDEX - 1 ))
PAIR_IDX=$(( IDX / 3 ))
REPLICATE=$(( IDX % 3 ))

HUMAN="${HUMAN_SAMPLES[$PAIR_IDX]}"
MOUSE="${MOUSE_SAMPLES[$PAIR_IDX]}"
SAMPLE_PREFIX="${HUMAN}_${MOUSE}"

TOTAL_COUNT="50000000"
MIXTURE="60p"
INDEX_PATH="${DATA_DIR}/xengsort/test/converted_index"

MIXTURE_DIR="${DATA_DIR}/mixtures/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
OUT_PREFIX="${DATA_DIR}/runtime_memory/xengsort_newindex/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}/mixed_${REPLICATE}"
mkdir -p "$(dirname "$OUT_PREFIX")"

echo "Sample: ${SAMPLE_PREFIX}, replicate: ${REPLICATE}"

xengsort classify \
    --index  "$INDEX_PATH" \
    --fastq  "${MIXTURE_DIR}/mixed_${REPLICATE}_r1.fastq.gz" \
    --pairs  "${MIXTURE_DIR}/mixed_${REPLICATE}_r2.fastq.gz" \
    --prefix "$OUT_PREFIX" \
    --mode   count \
    --threads 8
