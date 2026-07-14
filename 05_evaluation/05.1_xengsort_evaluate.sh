#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

XENGSORT_DIR="${DATA_DIR}/xengsort"

echo "Xengsort Evaluation"

for PAIR in "${SAMPLE_PAIRS[@]}"; do
    read -r HUMAN_SAMPLE MOUSE_SAMPLE <<< "$PAIR"
    SAMPLE_PREFIX="${HUMAN_SAMPLE}_${MOUSE_SAMPLE}"
    echo "=== ${SAMPLE_PREFIX} ==="

    for TOTAL_COUNT in "${TOTAL_COUNTS[@]}"; do
        for MIXTURE in "${MIXTURES[@]}"; do
            echo "${TOTAL_COUNT}, ${MIXTURE}"

            PAIRED_COUNT=$(( TOTAL_COUNT * 2 ))
            BAM_DIR="${XENGSORT_DIR}/${SAMPLE_PREFIX}/${TOTAL_COUNT}/${MIXTURE}"
            OUTPUT_FILE="${BAM_DIR}/evaluation.tsv"

            echo -e "ID\tSample_Prefix\tTotal_Reads\tMixture\tReplicate\t\
Human_Assigned\tMouse_Assigned\tAmb_Assigned\tBoth_Assigned\tNeither_Assigned\t\
Human_Human\tHuman_Mouse\tMouse_Mouse\tMouse_Human\t\
Amb_Human\tAmb_Mouse\tBoth_Human\tBoth_Mouse\tNeither_Human\tNeither_Mouse" > "$OUTPUT_FILE"

            for REPLICATE in "${REPLICATES[@]}"; do
                echo "${REPLICATE}"

                # --- Human only ---
                HUMAN_R1="${BAM_DIR}/mixed_${REPLICATE}-graft.1.fq.gz"
                HUMAN_ASSIGNED=$(( $(zcat "$HUMAN_R1" | wc -l) / 4 * 2 ))
                HUMAN_HUMAN=$(( $(zcat "$HUMAN_R1" | awk 'NR%4==1 && /^@human/ {c++} END{print c}') * 2 ))
                HUMAN_MOUSE=$(( HUMAN_ASSIGNED - HUMAN_HUMAN ))

                # --- Mouse only ---
                MOUSE_R1="${BAM_DIR}/mixed_${REPLICATE}-host.1.fq.gz"
                MOUSE_ASSIGNED=$(( $(zcat "$MOUSE_R1" | wc -l) / 4 * 2 ))
                MOUSE_MOUSE=$(( $(zcat "$MOUSE_R1" | awk 'NR%4==1 && /^@mouse/ {c++} END{print c}') * 2 ))
                MOUSE_HUMAN=$(( MOUSE_ASSIGNED - MOUSE_MOUSE ))

                # --- Ambiguous ---
                AMB_R1="${BAM_DIR}/mixed_${REPLICATE}-ambiguous.1.fq.gz"
                AMB_ASSIGNED=$(( $(zcat "$AMB_R1" | wc -l) / 4 * 2 ))
                AMB_HUMAN=$(( $(zcat "$AMB_R1" | awk 'NR%4==1 && /^@human/ {c++} END{print c}') * 2 ))
                AMB_MOUSE=$(( AMB_ASSIGNED - AMB_HUMAN ))

                # --- Both ---
                BOTH_R1="${BAM_DIR}/mixed_${REPLICATE}-both.1.fq.gz"
                BOTH_ASSIGNED=$(( $(zcat "$BOTH_R1" | wc -l) / 4 * 2 ))
                BOTH_HUMAN=$(( $(zcat "$BOTH_R1" | awk 'NR%4==1 && /^@human/ {c++} END{print c}') * 2 ))
                BOTH_MOUSE=$(( BOTH_ASSIGNED - BOTH_HUMAN ))

                # --- Neither ---
                NEITHER_R1="${BAM_DIR}/mixed_${REPLICATE}-neither.1.fq.gz"
                NEITHER_ASSIGNED=$(( $(zcat "$NEITHER_R1" | wc -l) / 4 * 2 ))
                NEITHER_HUMAN=$(( $(zcat "$NEITHER_R1" | awk 'NR%4==1 && /^@human/ {c++} END{print c}') * 2 ))
                NEITHER_MOUSE=$(( NEITHER_ASSIGNED - NEITHER_HUMAN ))

                ID="${SAMPLE_PREFIX}_${PAIRED_COUNT}_${MIXTURE}_${REPLICATE}"

                echo -e "${ID}\t${SAMPLE_PREFIX}\t${PAIRED_COUNT}\t${MIXTURE}\t${REPLICATE}\t\
${HUMAN_ASSIGNED}\t${MOUSE_ASSIGNED}\t${AMB_ASSIGNED}\t${BOTH_ASSIGNED}\t${NEITHER_ASSIGNED}\t\
${HUMAN_HUMAN}\t${HUMAN_MOUSE}\t${MOUSE_MOUSE}\t${MOUSE_HUMAN}\t\
${AMB_HUMAN}\t${AMB_MOUSE}\t${BOTH_HUMAN}\t${BOTH_MOUSE}\t${NEITHER_HUMAN}\t${NEITHER_MOUSE}" >> "$OUTPUT_FILE"

            done    # REPLICATE
        done        # MIXTURE
    done            # TOTAL_COUNT
done                # SAMPLE_PAIRS
