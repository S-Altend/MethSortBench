#!/bin/bash
# Generate evaluation.tsv for xengsort outputs (RRBS + RREMS).
# RREMS is paired-end; only .1.fq.gz files are counted to avoid double-counting.
shopt -s nullglob
set -euo pipefail

USE_START_SITES="${USE_START_SITES:-0}"

source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

if [[ "$USE_START_SITES" == "1" ]]; then
    METHOD="xengsort_mspi_newindex"
else
    METHOD="xengsort_newindex"
fi

for ASSAY in rrems; do
    OUT_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/${METHOD}"
    RESULTS_DIR="${REPO_DIR}/09_pdx_rrems_rrbs/results/xengsort_newindex_${ASSAY}"
    [[ "$USE_START_SITES" == "1" ]] && RESULTS_DIR="${RESULTS_DIR}_mspi"
    mkdir -p "$RESULTS_DIR"
    echo "=== ${ASSAY} ==="

    [[ "$ASSAY" == "rrems" ]] && GLOB_SUFFIX=".1.fq.gz" || GLOB_SUFFIX=".fq.gz"

    for SAMPLE_DIR in "$OUT_DIR"/*/; do
        SAMPLE=$(basename "$SAMPLE_DIR")
        SAMPLE_RESULTS="${RESULTS_DIR}/${SAMPLE}"
        mkdir -p "$SAMPLE_RESULTS"
        TSV_FILE="${SAMPLE_RESULTS}/evaluation.tsv"
        # if [[ -s "$TSV_FILE" ]]; then
        #     echo "  ${SAMPLE}: skipped (already exists)"
        #     continue
        # fi
        echo -e "Category\tReads\tSample\tMethod" > "$TSV_FILE"

        for F in "$SAMPLE_DIR"/${SAMPLE}-*${GLOB_SUFFIX}; do
            FILENAME=$(basename "$F")
            CATEGORY="${FILENAME#${SAMPLE}-}"
            CATEGORY="${CATEGORY%${GLOB_SUFFIX}}"
            READS=$(zcat "$F" | wc -l | awk '{print int($1/4)}')
            echo -e "${CATEGORY}\t${READS}\t${SAMPLE}\t${METHOD}" >> "$TSV_FILE"
        done

        echo "  ${SAMPLE}: done"
    done

    echo "  Written to ${RESULTS_DIR}"
done

shopt -u nullglob
echo "All evaluation.tsv files written."
