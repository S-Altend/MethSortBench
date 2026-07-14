#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

PAIRS=(
    "wgbs-human-pancreas-organoid1 wgbs-mouse-pancreas-organoid1"
    "wgbs-human-pancreas-organoid2 wgbs-mouse-pancreas-organoid2"
    "wgbs-human-pancreas-organoid3 wgbs-mouse-pancreas-organoid3"
    "wgbs-human-brca-cl1 wgbs-mouse-bm-hsc1"
)

ICRG_DIR="${DATA_DIR}/icrg"

for PAIR in "${PAIRS[@]}"; do
    HUMAN_SAMPLE=$(echo "$PAIR" | awk '{print $1}')
    MOUSE_SAMPLE=$(echo "$PAIR" | awk '{print $2}')
    SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"

    echo "ICRG Evaluation: ${SAMPLE_PREFIX}"

    for TOTAL_COUNT in "${TOTAL_COUNTS[@]}"; do
        PAIRED_COUNT=$(( 2 * TOTAL_COUNT ))
        for MIXTURE in "${MIXTURES[@]}"; do

            echo "  ${TOTAL_COUNT}, ${MIXTURE}"

            BAM_DIR="${ICRG_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
            OUTPUT_FILE="${BAM_DIR}/evaluation.tsv"

            echo -e "ID\tSample_Prefix\tTotal_Reads\tMixture\tReplicate\t\
Human_Assigned\tMouse_Assigned\tUnmapped\t\
Human_Human\tHuman_Mouse\tMouse_Mouse\tMouse_Human\tUnmapped_Human\tUnmapped_Mouse" > "$OUTPUT_FILE"

            for REPLICATE in "${REPLICATES[@]}"; do

                echo "    replicate ${REPLICATE}"

                BAM_FILE="${BAM_DIR}/mixed_${REPLICATE}_combined.sorted.bam"

                # -F 0x904: exclude unmapped, secondary, supplementary
                HUMAN_ASSIGNED=$(samtools view -F 0x904 "$BAM_FILE" --threads 64 | awk '$3 !~ /^m\./ {count++} END{print count+0}')
                MOUSE_ASSIGNED=$(samtools view -F 0x904 "$BAM_FILE" --threads 64 | awk '$3 ~ /^m\./ {count++} END{print count+0}')

                # -F 0x900 -f 0x4: unmapped only (not secondary/supplementary)
                UNMAPPED=$(samtools view -F 0x900 -f 0x4 "$BAM_FILE" --threads 64 | wc -l)

                # Human-origin reads mapped to human (TP)
                HUMAN_HUMAN=$(samtools view -F 0x904 "$BAM_FILE" --threads 64 | awk '$3 !~ /^m\./' | grep -c "^human")
                # Mouse-origin reads mapped to human (FP)
                HUMAN_MOUSE=$(( HUMAN_ASSIGNED - HUMAN_HUMAN ))

                # Mouse-origin reads mapped to mouse (TN)
                MOUSE_MOUSE=$(samtools view -F 0x904 "$BAM_FILE" --threads 64 | awk '$3 ~ /^m\./' | grep -c "^mouse")
                # Human-origin reads mapped to mouse (FN)
                MOUSE_HUMAN=$(( MOUSE_ASSIGNED - MOUSE_MOUSE ))

                # Human-origin reads unmapped (FN)
                UNMAPPED_HUMAN=$(samtools view -F 0x900 -f 0x4 "$BAM_FILE" --threads 64 | grep -c "^human")
                # Mouse-origin reads unmapped (TN)
                UNMAPPED_MOUSE=$(( UNMAPPED - UNMAPPED_HUMAN ))

                ID="${SAMPLE_PREFIX}_${PAIRED_COUNT}_${MIXTURE}_${REPLICATE}"

                echo -e "${ID}\t${SAMPLE_PREFIX}\t${PAIRED_COUNT}\t${MIXTURE}\t${REPLICATE}\t\
${HUMAN_ASSIGNED}\t${MOUSE_ASSIGNED}\t${UNMAPPED}\t\
${HUMAN_HUMAN}\t${HUMAN_MOUSE}\t${MOUSE_MOUSE}\t${MOUSE_HUMAN}\t${UNMAPPED_HUMAN}\t${UNMAPPED_MOUSE}" >> "$OUTPUT_FILE"
            done
        done
    done
done
