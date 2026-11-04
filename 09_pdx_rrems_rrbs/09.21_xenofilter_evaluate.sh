#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

# Usage:
#   ASSAY=rrbs bash 09.21xenofilter_evaluate.sh
#   ASSAY=rrems bash 09.21xenofilter_evaluate.sh
#   ASSAY=rrbs USE_START_SITES=1 bash 09.21xenofilter_evaluate.sh
#   ASSAY=rrems USE_START_SITES=1 bash 09.21xenofilter_evaluate.sh
ASSAY="${ASSAY:-rrbs}"
USE_START_SITES="${USE_START_SITES:-0}"
LABEL=$( [[ "$USE_START_SITES" == "1" ]] && echo "_mspi" || echo "" )

METHOD="XenofilteR"
XENOFILTER_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/xenofilter${LABEL}"
HUMAN_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/pipelines/pipeline_human${LABEL}/bwameth/alignments"
RESULTS_DIR="${REPO_DIR}/09_pdx_rrems_rrbs/results/xenofilter_${ASSAY}${LABEL}"
mkdir -p "$RESULTS_DIR"

count_bam() {
    local F="$1"
    if [[ ! -s "$F" ]]; then echo 0; return; fi
    samtools view -F 0x900 -c "$F"
}

for SAMPLE_DIR in "$XENOFILTER_DIR"/*/; do
    SAMPLE=$(basename "$SAMPLE_DIR")
    echo "Evaluating ${SAMPLE}..."

    FILTERED_BAM="${SAMPLE_DIR}Filtered_bams/${SAMPLE}_Filtered.bam"
    HUMAN_BAM="${HUMAN_DIR}/${SAMPLE}.sorted.bam"

    HUMAN=$(count_bam "$FILTERED_BAM")
    TOTAL=$(count_bam "$HUMAN_BAM")
    DISCARDED=$(( TOTAL - HUMAN ))

    SAMPLE_RESULT_DIR="${RESULTS_DIR}/${SAMPLE}"
    mkdir -p "$SAMPLE_RESULT_DIR"
    OUT_TSV="${SAMPLE_RESULT_DIR}/evaluation.tsv"

    echo -e "Category\tReads\tSample\tMethod" > "$OUT_TSV"
    echo -e "human\t${HUMAN}\t${SAMPLE}\t${METHOD}" >> "$OUT_TSV"
    echo -e "discarded\t${DISCARDED}\t${SAMPLE}\t${METHOD}" >> "$OUT_TSV"

    echo "Saved to ${OUT_TSV}"
done
