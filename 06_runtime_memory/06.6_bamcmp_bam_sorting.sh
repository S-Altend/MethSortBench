#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

HUMAN_SAMPLE="wgbs-human-pancreas-organoid1"
MOUSE_SAMPLE="wgbs-mouse-pancreas-organoid1"
SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"

BAMCMP_DIR="${DATA_DIR}/runtime_memory/bamcmp"
mkdir -p "$BAMCMP_DIR"

TOTAL_COUNTS=("50000000")
MIXTURES=("60p")
REPLICATES=("0" "1" "2")

for TOTAL_COUNT in "${TOTAL_COUNTS[@]}"; do
    for MIXTURE in "${MIXTURES[@]}"; do
        for REPLICATE in "${REPLICATES[@]}"; do
            echo "${HUMAN_SAMPLE}, ${MOUSE_SAMPLE}"
            echo "${TOTAL_COUNT}, ${MIXTURE}, ${REPLICATE}"
            BAM_DIR="${ALIGNMENT_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
            HUMAN_BAM="${BAM_DIR}/mixed_${REPLICATE}_${HUMAN_GENOME}.sorted.bam"
            MOUSE_BAM="${BAM_DIR}/mixed_${REPLICATE}_${MOUSE_GENOME}.sorted.bam"

            echo "Sorting Human bam"
            samtools sort --threads 16 -n -o $HUMAN_BAM $HUMAN_BAM
            echo "Sorting Mouse bam"
            samtools sort --threads 16 -n -o $MOUSE_BAM $MOUSE_BAM

        done
    done
done
