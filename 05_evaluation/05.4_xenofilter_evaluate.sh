#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

HUMAN_SAMPLE="wgbs-human-pancreas-organoid3"
MOUSE_SAMPLE="wgbs-mouse-pancreas-organoid3"
SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"

XENOFILTER_DIR="${DATA_DIR}/xenofilter"

echo "Xenofilter Evaluation"
echo "${SAMPLE_PREFIX}"

for TOTAL_COUNT in "${TOTAL_COUNTS[@]}"; do
    for MIXTURE in "${MIXTURES[@]}"; do

        echo "${TOTAL_COUNT}, ${MIXTURE}"

        PAIRED_COUNT=$(( TOTAL_COUNT * 2 ))
        FRACTION=$(echo "${MIXTURE//p/}" | awk '{printf "%.4f", $1/100}')
        BAM_DIR="${XENOFILTER_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
        OUTPUT_FILE="${BAM_DIR}/evaluation.tsv"

        echo -e "ID\tSample_Prefix\tTotal_Reads\tMixture\tReplicate\tHuman_Assigned\tHuman_Human\tHuman_Mouse\tMouse_Mouse\tMouse_Human" > "$OUTPUT_FILE"

        for REPLICATE in "${REPLICATES[@]}"; do
            HUMAN_FILE="${BAM_DIR}/${REPLICATE}_filtered.bam"
            echo "${REPLICATE}"

            ID="${SAMPLE_PREFIX}_${PAIRED_COUNT}_${MIXTURE}_${REPLICATE}"

            HUMAN_ASSIGNED=$(samtools view -F 0x900 -c "$HUMAN_FILE")

            TOTAL_READ_HUMAN=$(awk -v count="$PAIRED_COUNT" -v frac="$FRACTION" 'BEGIN {printf "%.0f", count * frac}')
            TOTAL_READ_MOUSE=$(awk -v count="$PAIRED_COUNT" -v frac="$FRACTION" 'BEGIN {printf "%.0f", count * (1 - frac)}')

            HUMAN_HUMAN=$(samtools view -F 0x900 "$HUMAN_FILE" | grep -c "^human")
            HUMAN_MOUSE=$(( HUMAN_ASSIGNED - HUMAN_HUMAN ))
            MOUSE_MOUSE=$(( TOTAL_READ_MOUSE - HUMAN_MOUSE ))
            MOUSE_HUMAN=$(( TOTAL_READ_HUMAN - HUMAN_HUMAN ))

            echo -e "${ID}\t${SAMPLE_PREFIX}\t${PAIRED_COUNT}\t${MIXTURE}\t${REPLICATE}\t${HUMAN_ASSIGNED}\t${HUMAN_HUMAN}\t${HUMAN_MOUSE}\t${MOUSE_MOUSE}\t${MOUSE_HUMAN}" >> "$OUTPUT_FILE"
        done
    done
done
