#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

# Usage:
#   ASSAY=rrbs bash 09.18_bamcmp_evaluate.sh
#   ASSAY=rrems bash 09.18_bamcmp_evaluate.sh
#   ASSAY=rrbs USE_START_SITES=1 bash 09.18_bamcmp_evaluate.sh
#   ASSAY=rrems USE_START_SITES=1 bash 09.18_bamcmp_evaluate.sh
ASSAY="${ASSAY:-rrbs}"
USE_START_SITES="${USE_START_SITES:-0}"
LABEL=$( [[ "$USE_START_SITES" == "1" ]] && echo "_mspi" || echo "" )

BAMCMP_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/bamcmp${LABEL}"
METHOD="bamcmp"
RESULTS_DIR="${REPO_DIR}/09_pdx_guillen_2022/results/bamcmp_${ASSAY}${LABEL}"
mkdir -p "$RESULTS_DIR"

count_bam() {
    local F="$1"
    if [[ ! -s "$F" ]]; then echo 0; return; fi
    samtools view -F 0x900 -c "$F"
}

for SAMPLE_DIR in "$BAMCMP_DIR"/*/; do
    SAMPLE=$(basename "$SAMPLE_DIR")
    echo "Evaluating ${SAMPLE}..."

    HUMAN_ONLY=$(count_bam "${SAMPLE_DIR}${SAMPLE}.humanOnly.bam")
    HUMAN_BETTER=$(count_bam "${SAMPLE_DIR}${SAMPLE}.humanBetter.bam")
    MOUSE_ONLY=$(count_bam "${SAMPLE_DIR}${SAMPLE}.mouseOnly.bam")
    MOUSE_BETTER=$(count_bam "${SAMPLE_DIR}${SAMPLE}.mouseBetter.bam")

    SAMPLE_DIR="${RESULTS_DIR}/${SAMPLE}"
    mkdir -p "$SAMPLE_DIR"
    OUT_TSV="${SAMPLE_DIR}/evaluation.tsv"
    echo -e "Category\tReads\tSample\tMethod" > "$OUT_TSV"
    echo -e "humanOnly\t${HUMAN_ONLY}\t${SAMPLE}\t${METHOD}" >> "$OUT_TSV"
    echo -e "humanBetter\t${HUMAN_BETTER}\t${SAMPLE}\t${METHOD}" >> "$OUT_TSV"
    echo -e "mouseOnly\t${MOUSE_ONLY}\t${SAMPLE}\t${METHOD}" >> "$OUT_TSV"
    echo -e "mouseBetter\t${MOUSE_BETTER}\t${SAMPLE}\t${METHOD}" >> "$OUT_TSV"

    echo "Saved to ${OUT_TSV}"
done
