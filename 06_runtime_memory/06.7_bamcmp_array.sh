#!/usr/bin/env bash
#BSUB -J bamcmp_runmem[1-12]
#BSUB -n 8
#BSUB -M 80G
#BSUB -R "rusage[mem=80G]"
#BSUB -q long
#BSUB -o logs/bamcmp_%I.out
#BSUB -e logs/bamcmp_%I.err

set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

# 4 sample pairs × 3 replicates = 12 jobs
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

BAM_DIR="${ALIGNMENT_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
HUMAN_BAM="${BAM_DIR}/mixed_${REPLICATE}_${HUMAN_GENOME}.sorted.bam"
MOUSE_BAM="${BAM_DIR}/mixed_${REPLICATE}_${MOUSE_GENOME}.sorted.bam"

OUTPUT_DIR="${DATA_DIR}/runtime_memory/bamcmp/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
mkdir -p "$OUTPUT_DIR"

echo "Sample: ${SAMPLE_PREFIX}, replicate: ${REPLICATE}"

bamcmp -n -t 8 \
    -1 "$HUMAN_BAM" \
    -2 "$MOUSE_BAM" \
    -a "${OUTPUT_DIR}/mixed_${REPLICATE}.humanOnly.bam" \
    -A "${OUTPUT_DIR}/mixed_${REPLICATE}.humanBetter.bam" \
    -b "${OUTPUT_DIR}/mixed_${REPLICATE}.mouseOnly.bam" \
    -B "${OUTPUT_DIR}/mixed_${REPLICATE}.mouseBetter.bam" \
    -s match
