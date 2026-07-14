#!/usr/bin/env bash
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

# HUMAN_SAMPLE="wgbs-human-pancreas-organoid3"  MOUSE_SAMPLE="wgbs-mouse-pancreas-organoid3"
HUMAN_SAMPLE="wgbs-human-brca-cl1"
MOUSE_SAMPLE="wgbs-mouse-bm-hsc1"
SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"

# Runtime/memory subset
TOTAL_COUNTS=("50000000")
MIXTURES=("60p")
REPLICATES=("0" "1" "2")

for TOTAL_COUNT in "${TOTAL_COUNTS[@]}"; do
    for MIXTURE in "${MIXTURES[@]}"; do
        for REPLICATE in "${REPLICATES[@]}"; do
            BAM_DIR="${ALIGNMENT_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
            for GENOME in "${HUMAN_GENOME}" "${MOUSE_GENOME}"; do
                BAM="${BAM_DIR}/mixed_${REPLICATE}_${GENOME}.sorted.bam"
                BAM_COORD="${BAM_DIR}/mixed_${REPLICATE}_${GENOME}.coord.sorted.bam"
                if [[ -f "$BAM" ]]; then
                    echo "Sorting ${GENOME}: $BAM"
                    samtools sort -o "$BAM_COORD" "$BAM"
                    samtools index "$BAM_COORD"
                fi
            done
        done
    done
done
