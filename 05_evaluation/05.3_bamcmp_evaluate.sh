#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

HUMAN_SAMPLE="wgbs-human-pancreas-organoid3"
MOUSE_SAMPLE="wgbs-mouse-pancreas-organoid3"
SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"

BAMCMP_DIR="${DATA_DIR}/bamcmp"
BAMCMP_DIR="/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/data/bamcmp"
echo "Bamcmp Evaluation"
echo "$SAMPLE_PREFIX"

for TOTAL_COUNT in "${TOTAL_COUNTS[@]}"; do
    PAIRED_COUNT=$(( TOTAL_COUNT * 2 ))

    for MIXTURE in "${MIXTURES[@]}"; do

        echo "${TOTAL_COUNT}, ${MIXTURE}"

        BAM_DIR="${BAMCMP_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
        OUTPUT_FILE="${BAM_DIR}/evaluation.tsv"

        echo -e "ID\tSample_Prefix\tTotal_Reads\tMixture\tReplicate\t\
Human_Assigned\tMouse_Assigned\tAmb_Human_Assigned\tAmb_Mouse_Assigned\t\
Human_Human\tHuman_Mouse\tMouse_Mouse\tMouse_Human\tAmb_Human_Human\tAmb_Human_Mouse\tAmb_Mouse_Mouse\tAmb_Mouse_Human" > "$OUTPUT_FILE"

        for REPLICATE in "${REPLICATES[@]}"; do

            # --- Human only ---
            HUMAN_FILE="${BAM_DIR}/mixed_${REPLICATE}.bamcmp.humanOnly.bam"
            HUMAN_ASSIGNED=$(samtools view -F 0x900 -c "$HUMAN_FILE")
            HUMAN_HUMAN=$(samtools view -F 0x900 "$HUMAN_FILE" --threads 64 | grep "^human" | wc -l)
            HUMAN_MOUSE=$(( HUMAN_ASSIGNED - HUMAN_HUMAN ))

            # --- Mouse only ---
            MOUSE_FILE="${BAM_DIR}/mixed_${REPLICATE}.bamcmp.mouseOnly.bam"
            MOUSE_ASSIGNED=$(samtools view -F 0x900 -c "$MOUSE_FILE")
            MOUSE_MOUSE=$(samtools view -F 0x900 "$MOUSE_FILE" --threads 64 | grep "^mouse" | wc -l)
            MOUSE_HUMAN=$(( MOUSE_ASSIGNED - MOUSE_MOUSE ))

            # --- Ambiguous: humanBetter ---
            AMB_HUMAN_FILE="${BAM_DIR}/mixed_${REPLICATE}.bamcmp.humanBetter.bam"
            AMB_HUMAN_ASSIGNED=$(samtools view -F 0x900 -c "$AMB_HUMAN_FILE")
            AMB_HUMAN_HUMAN=$(samtools view -F 0x900 "$AMB_HUMAN_FILE" --threads 64 | grep "^human" | wc -l)
            AMB_HUMAN_MOUSE=$(( AMB_HUMAN_ASSIGNED - AMB_HUMAN_HUMAN ))

            # --- Ambiguous: mouseBetter ---
            AMB_MOUSE_FILE="${BAM_DIR}/mixed_${REPLICATE}.bamcmp.mouseBetter.bam"
            AMB_MOUSE_ASSIGNED=$(samtools view -F 0x900 -c "$AMB_MOUSE_FILE")
            AMB_MOUSE_MOUSE=$(samtools view -F 0x900 "$AMB_MOUSE_FILE" --threads 64 | grep "^mouse" | wc -l)
            AMB_MOUSE_HUMAN=$(( AMB_MOUSE_ASSIGNED - AMB_MOUSE_MOUSE ))

            ID="${SAMPLE_PREFIX}_${PAIRED_COUNT}_${MIXTURE}_${REPLICATE}"

            echo -e "${ID}\t${SAMPLE_PREFIX}\t${PAIRED_COUNT}\t${MIXTURE}\t${REPLICATE}\t\
${HUMAN_ASSIGNED}\t${MOUSE_ASSIGNED}\t${AMB_HUMAN_ASSIGNED}\t${AMB_MOUSE_ASSIGNED}\t\
${HUMAN_HUMAN}\t${HUMAN_MOUSE}\t${MOUSE_MOUSE}\t${MOUSE_HUMAN}\t${AMB_HUMAN_HUMAN}\t${AMB_HUMAN_MOUSE}\t${AMB_MOUSE_MOUSE}\t${AMB_MOUSE_HUMAN}" >> "$OUTPUT_FILE"

        done
    done
done
