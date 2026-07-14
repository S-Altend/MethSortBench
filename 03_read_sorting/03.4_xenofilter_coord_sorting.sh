#!/usr/bin/env bash
#BSUB -J "coord_sort[1-8]"
#BSUB -q verylong
#BSUB -n 8
#BSUB -R "rusage[mem=80GB]"
#BSUB -o logs/coord_sort_%I.out
#BSUB -e logs/coord_sort_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

ALIGNMENT_DIR="${DATA_DIR}/methylseq_refseq"

IDX=$(( LSB_JOBINDEX - 1 ))
PAIR_IDX=$(( IDX / 2 ))
DEPTH_IDX=$(( IDX % 2 ))
read -r HUMAN_SAMPLE MOUSE_SAMPLE <<< "${SAMPLE_PAIRS[$PAIR_IDX]}"
TOTAL_COUNT="${TOTAL_COUNTS[$DEPTH_IDX]}"
SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"

for MIXTURE in "${MIXTURES[@]}"; do
    for REPLICATE in "${REPLICATES[@]}"; do
        BAM_DIR="${ALIGNMENT_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
        for GENOME in "${HUMAN_GENOME}" "${MOUSE_GENOME}"; do
            BAM="${BAM_DIR}/mixed_${REPLICATE}_${GENOME}.sorted.bam"
            BAM_COORD="${BAM_DIR}/mixed_${REPLICATE}_${GENOME}.coord.sorted.bam"
            if [[ -f "$BAM_COORD" ]]; then
                echo "Skipping ${GENOME} (coord.sorted.bam exists): $BAM_COORD"
            elif [[ -f "$BAM" ]]; then
                echo "Sorting ${GENOME}: $BAM"
                samtools sort --threads 8 -o "$BAM_COORD" "$BAM"
                samtools index "$BAM_COORD"
            fi
        done
    done
done
