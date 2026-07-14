#!/usr/bin/env bash
#BSUB -J "bamcmp[1-8]"
#BSUB -q verylong
#BSUB -n 8
#BSUB -R "rusage[mem=24GB]"
#BSUB -o logs/bamcmp_%I.out
#BSUB -e logs/bamcmp_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

ALIGNMENT_DIR="${DATA_DIR}/methylseq_refseq"

IDX=$(( LSB_JOBINDEX - 1 ))
PAIR_IDX=$(( IDX / 2 ))
DEPTH_IDX=$(( IDX % 2 ))
read -r HUMAN_SAMPLE MOUSE_SAMPLE <<< "${SAMPLE_PAIRS[$PAIR_IDX]}"
TOTAL_COUNT="${TOTAL_COUNTS[$DEPTH_IDX]}"
SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"

BAMCMP_DIR="${DATA_DIR}/bamcmp"

for MIXTURE in "${MIXTURES[@]}"; do
    for REPLICATE in "${REPLICATES[@]}"; do
        BAM_DIR="${ALIGNMENT_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
        HUMAN_BAM="${BAM_DIR}/mixed_${REPLICATE}_${HUMAN_GENOME}.name.sorted.bam"
        MOUSE_BAM="${BAM_DIR}/mixed_${REPLICATE}_${MOUSE_GENOME}.name.sorted.bam"

        if [[ -f "$HUMAN_BAM" ]]; then
            echo "Skipping human name sort (exists): $HUMAN_BAM"
        else
            echo "Sorting Human bam"
            echo $MIXTURE
            samtools sort --threads 16 -n -o "$HUMAN_BAM" "${BAM_DIR}/mixed_${REPLICATE}_${HUMAN_GENOME}.sorted.bam"
        fi
        if [[ -f "$MOUSE_BAM" ]]; then
            echo "Skipping mouse name sort (exists): $MOUSE_BAM"
        else
            echo "Sorting Mouse bam"
            samtools sort --threads 16 -n -o "$MOUSE_BAM" "${BAM_DIR}/mixed_${REPLICATE}_${MOUSE_GENOME}.sorted.bam"
        fi

        OUT_DIR="${BAMCMP_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
        mkdir -p "$OUT_DIR"
        if [[ -f "${OUT_DIR}/mixed_${REPLICATE}.bamcmp.humanOnly.bam" ]]; then
            echo "Skipping (output exists): ${TOTAL_COUNT}, ${MIXTURE}, rep${REPLICATE}"
            continue
        fi
        echo "Running bamcmp: ${SAMPLE_PREFIX}, ${TOTAL_COUNT}, ${MIXTURE}, rep${REPLICATE}"
        bamcmp -n -t 16 \
            -1 "$HUMAN_BAM" \
            -2 "$MOUSE_BAM" \
            -a "${OUT_DIR}/mixed_${REPLICATE}.bamcmp.humanOnly.bam" \
            -A "${OUT_DIR}/mixed_${REPLICATE}.bamcmp.humanBetter.bam" \
            -b "${OUT_DIR}/mixed_${REPLICATE}.bamcmp.mouseOnly.bam" \
            -B "${OUT_DIR}/mixed_${REPLICATE}.bamcmp.mouseBetter.bam" \
            -s match
        echo "Finished ${TOTAL_COUNT}, ${MIXTURE}, ${REPLICATE}"
    done
done
