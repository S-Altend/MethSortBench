#!/usr/bin/env bash
# Usage:
#   bash 09.12_icrg_evaluate.sh               → pipeline_icrg/   → results/icrg{,_rrems}/
#   USE_START_SITES=1 bash 09.12_icrg_evaluate.sh → pipeline_icrg_mspi/ → results/icrg{,_rrems}_mspi/
set -euo pipefail

USE_START_SITES="${USE_START_SITES:-0}"

source "$(dirname "$0")/../config.sh"

if [[ "$USE_START_SITES" == "1" ]]; then
    PIPELINE_SUFFIX="_mspi"
    METHOD="icrg_mspi"
else
    PIPELINE_SUFFIX=""
    METHOD="icrg"
fi

for ASSAY in rrbs rrems; do
    if [[ "$ASSAY" == "rrbs" ]]; then
        BAM_DIR="${GUILLEN_DATA_DIR}/rrbs/pipelines/pipeline_icrg${PIPELINE_SUFFIX}/bwameth/alignments"
        BAM_SUFFIX=".sorted.bam"
        OUT_BASE="${REPO_DIR}/09_pdx_rrems_rrbs/results/icrg_rrbs${PIPELINE_SUFFIX}"
    else
        BAM_DIR="${GUILLEN_DATA_DIR}/rrems/pipelines/pipeline_icrg${PIPELINE_SUFFIX}/bwameth/alignments"
        BAM_SUFFIX=".sorted.bam"
        OUT_BASE="${REPO_DIR}/09_pdx_rrems_rrbs/results/icrg_rrems${PIPELINE_SUFFIX}"
    fi

    echo "=== ${ASSAY} ==="

    for BAM in "$BAM_DIR"/*${BAM_SUFFIX}; do
        SAMPLE=$(basename "$BAM" "$BAM_SUFFIX")
        OUT_DIR="${OUT_BASE}/${SAMPLE}"
        mkdir -p "$OUT_DIR"

        echo "  Evaluating ${SAMPLE}..."

        MOUSE_ALIGNED=$(samtools view -F 0x904 --threads 16 "$BAM" | awk '$3 ~ /^m\./ {count++} END{print count+0}')
        HUMAN_ALIGNED=$(samtools view -F 0x904 --threads 16 "$BAM" | awk '$3 !~ /^m\./ {count++} END{print count+0}')
        UNMAPPED=$(samtools view -F 0x900 --threads 16 -f 0x4 "$BAM" | wc -l)

        {
            echo -e "Category\tReads\tSample\tMethod"
            echo -e "human\t${HUMAN_ALIGNED}\t${SAMPLE}\t${METHOD}"
            echo -e "mouse\t${MOUSE_ALIGNED}\t${SAMPLE}\t${METHOD}"
            echo -e "unmapped\t${UNMAPPED}\t${SAMPLE}\t${METHOD}"
        } > "${OUT_DIR}/evaluation.tsv"

        echo "  Saved to ${OUT_DIR}/evaluation.tsv"
    done
done

echo "All ICRG evaluation.tsv files written."
