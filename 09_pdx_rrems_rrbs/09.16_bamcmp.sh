#!/usr/bin/env bash
#BSUB -J guillen_bamcmp[1-20]
#BSUB -n 20
#BSUB -R "rusage[mem=150GB]"
#BSUB -q long
#BSUB -o logs/guillen_bamcmp_%I.out
#BSUB -e logs/guillen_bamcmp_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

# Usage:
#   ASSAY=rrbs bsub < 09.16_bamcmp.sh
#   ASSAY=rrems bsub < 09.16_bamcmp.sh
#   ASSAY=rrbs USE_START_SITES=1 bsub < 09.16_bamcmp.sh
#   ASSAY=rrems USE_START_SITES=1 bsub < 09.16_bamcmp.sh
# Array is [1-20] (rrems max); for rrbs (11 samples) indices 12-20 are skipped automatically.
ASSAY="${ASSAY:-rrbs}"
USE_START_SITES="${USE_START_SITES:-0}"
LABEL=$( [[ "$USE_START_SITES" == "1" ]] && echo "_mspi" || echo "" )

mkdir -p "${REPO_DIR}/09_pdx_rrems_rrbs/logs"

HUMAN_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/pipelines/pipeline_human${LABEL}/bwameth/alignments"
MOUSE_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/pipelines/pipeline_mouse${LABEL}/bwameth/alignments"
OUT_BASE="${GUILLEN_DATA_DIR}/${ASSAY}/bamcmp${LABEL}"

SAMPLES=( $(ls "$HUMAN_DIR"/*.sorted.bam | grep -v namesorted | grep -v '\.coord\.' | xargs -I{} basename {} .sorted.bam) )

if [[ $((LSB_JOBINDEX - 1)) -ge ${#SAMPLES[@]} ]]; then
    echo "Index ${LSB_JOBINDEX} out of range (${#SAMPLES[@]} samples for ASSAY=${ASSAY}), skipping."
    exit 0
fi

SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"
OUTPUT_DIR="${OUT_BASE}/${SAMPLE}"
mkdir -p "$OUTPUT_DIR"

HUMAN_BAM="${HUMAN_DIR}/${SAMPLE}.${HUMAN_GENOME}.namesorted.bam"
MOUSE_BAM="${MOUSE_DIR}/${SAMPLE}.${MOUSE_GENOME}.namesorted.bam"

echo "Sample: $SAMPLE | assay: $ASSAY | use-start-sites: $USE_START_SITES"

bamcmp -n -t 8 \
    -1 "$HUMAN_BAM" \
    -2 "$MOUSE_BAM" \
    -a "${OUTPUT_DIR}/${SAMPLE}.humanOnly.bam" \
    -A "${OUTPUT_DIR}/${SAMPLE}.humanBetter.bam" \
    -b "${OUTPUT_DIR}/${SAMPLE}.mouseOnly.bam" \
    -B "${OUTPUT_DIR}/${SAMPLE}.mouseBetter.bam" \
    -s match
