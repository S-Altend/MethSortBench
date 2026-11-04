#!/usr/bin/env bash
#BSUB -J guillen_xenofilter_sort[1-20]
#BSUB -n 16
#BSUB -R "rusage[mem=80GB]"
#BSUB -q long
#BSUB -o logs/guillen_xenofilter_sort_%I.out
#BSUB -e logs/guillen_xenofilter_sort_%I.err
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

# Usage:
#   ASSAY=rrbs bsub < 09.19_xenofilter_bam_sorting.sh
#   ASSAY=rrems bsub < 09.19_xenofilter_bam_sorting.sh
#   ASSAY=rrbs USE_START_SITES=1 bsub < 09.19_xenofilter_bam_sorting.sh
#   ASSAY=rrems USE_START_SITES=1 bsub < 09.19_xenofilter_bam_sorting.sh
# Array is [1-20] (rrems max); for rrbs (11 samples) indices 12-20 are skipped automatically.
ASSAY="${ASSAY:-rrbs}"
USE_START_SITES="${USE_START_SITES:-0}"
LABEL=$( [[ "$USE_START_SITES" == "1" ]] && echo "_mspi" || echo "" )

THREADS=16

mkdir -p "${REPO_DIR}/09_pdx_guillen_2022/logs"

HUMAN_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/pipelines/pipeline_human${LABEL}/bwameth/alignments"
MOUSE_DIR="${GUILLEN_DATA_DIR}/${ASSAY}/pipelines/pipeline_mouse${LABEL}/bwameth/alignments"

SAMPLES=( $(ls "$HUMAN_DIR"/*.sorted.bam | grep -v namesorted | grep -v coord | xargs -I{} basename {} .sorted.bam) )

if [[ $((LSB_JOBINDEX - 1)) -ge ${#SAMPLES[@]} ]]; then
    echo "Index ${LSB_JOBINDEX} out of range (${#SAMPLES[@]} samples for ASSAY=${ASSAY}), skipping."
    exit 0
fi

SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"
HUMAN_COORD="${HUMAN_DIR}/${SAMPLE}.coord.sorted.bam"
MOUSE_COORD="${MOUSE_DIR}/${SAMPLE}.coord.sorted.bam"

echo "Coord-sorting ${SAMPLE}..."

if [[ -f "$HUMAN_COORD" ]]; then
    echo "Skipping human (exists): $HUMAN_COORD"
else
    samtools sort --threads "$THREADS" \
        -o "$HUMAN_COORD" \
        "${HUMAN_DIR}/${SAMPLE}.sorted.bam"
    samtools index "$HUMAN_COORD"
fi

if [[ -f "$MOUSE_COORD" ]]; then
    echo "Skipping mouse (exists): $MOUSE_COORD"
else
    samtools sort --threads "$THREADS" \
        -o "$MOUSE_COORD" \
        "${MOUSE_DIR}/${SAMPLE%_0}_0.sorted.bam"
    samtools index "$MOUSE_COORD"
fi

echo "Done: ${SAMPLE}"
