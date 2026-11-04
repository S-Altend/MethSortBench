#!/usr/bin/env bash
#BSUB -J guillen_bamcmp_sort[1-20]
#BSUB -n 16
#BSUB -R "rusage[mem=80GB]"
#BSUB -q long
#BSUB -o logs/guillen_bamcmp_sort_%I.out
#BSUB -e logs/guillen_bamcmp_sort_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

# Usage:
#   ASSAY=rrbs bsub < 09.15_bamcmp_bam_sorting.sh
#   ASSAY=rrems bsub < 09.15_bamcmp_bam_sorting.sh
#   ASSAY=rrbs USE_START_SITES=1 bsub < 09.15_bamcmp_bam_sorting.sh
#   ASSAY=rrems USE_START_SITES=1 bsub < 09.15_bamcmp_bam_sorting.sh
# Array is [1-20] (rrems max); for rrbs (11 samples) indices 12-20 are skipped automatically.
ASSAY="${ASSAY:-rrbs}"
USE_START_SITES="${USE_START_SITES:-0}"
LABEL=$( [[ "$USE_START_SITES" == "1" ]] && echo "_mspi" || echo "" )

THREADS=16

mkdir -p "${REPO_DIR}/09_pdx_rrems_rrbs/logs"

HUMAN_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/pipelines/pipeline_human${LABEL}/bwameth/alignments"
MOUSE_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/pipelines/pipeline_mouse${LABEL}/bwameth/alignments"

SAMPLES=( $(ls "$HUMAN_DIR"/*.sorted.bam | grep -v namesorted | grep -v '\.coord\.' | xargs -I{} basename {} .sorted.bam) )

if [[ $((LSB_JOBINDEX - 1)) -ge ${#SAMPLES[@]} ]]; then
    echo "Index ${LSB_JOBINDEX} out of range (${#SAMPLES[@]} samples for ASSAY=${ASSAY}), skipping."
    exit 0
fi

SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"
HUMAN_OUT="${HUMAN_DIR}/${SAMPLE}.${HUMAN_GENOME}.namesorted.bam"
MOUSE_OUT="${MOUSE_DIR}/${SAMPLE}.${MOUSE_GENOME}.namesorted.bam"

echo "Name-sorting ${SAMPLE}..."

# if [[ -f "$HUMAN_OUT" ]]; then
#     echo "Skipping human (exists): $HUMAN_OUT"
# else
#     samtools sort --threads "$THREADS" -n \
#         -o "$HUMAN_OUT" \
#         "${HUMAN_DIR}/${SAMPLE}.sorted.bam"
# fi

if [[ -f "$MOUSE_OUT" ]]; then
    echo "Skipping mouse (exists): $MOUSE_OUT"
else
    # _mspi pipeline already embeds _0 in filenames; non-mspi mouse files have _0 appended
    MOUSE_SUFFIX=$( [[ "$USE_START_SITES" == "1" ]] && echo "" || echo "_0" )
    samtools sort --threads "$THREADS" -n \
        -o "$MOUSE_OUT" \
        "${MOUSE_DIR}/${SAMPLE}${MOUSE_SUFFIX}.sorted.bam"
fi

echo "Done: ${SAMPLE}"
