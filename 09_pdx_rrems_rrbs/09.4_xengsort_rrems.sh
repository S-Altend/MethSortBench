#!/usr/bin/env bash
#BSUB -J xengsort_rrems[1-20]
#BSUB -n 20
#BSUB -M 80000
#BSUB -R "rusage[mem=80000]"
#BSUB -o logs/logs_newindex/xengsort_rrems_%I.out
#BSUB -q long
#BSUB -e logs/logs_newindex/xengsort_rrems_%I.err
set -euo pipefail

# Pass USE_START_SITES=1 to enable xengsort's built-in MspI filter.
# Usage:
#   bsub < 09.4_xengsort_rrems.sh             → xengsort/   (standard)
#   USE_START_SITES=1 bsub < ...              → xengsort_mspi/

USE_START_SITES="${USE_START_SITES:-0}"

source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"
READ_DIR="${GUILLEN_DATA_DIR}/rrems/trimmed_reads"
INDEX_PATH="${DATA_DIR}/xengsort/test/converted_index"

if [[ "$USE_START_SITES" == "1" ]]; then
    OUT_DIR="${GUILLEN_DATA_DIR}/rrems/xengsort_mspi_newindex"
    START_SITES_FLAG="--use-start-sites"
else
    OUT_DIR="${GUILLEN_DATA_DIR}/rrems/xengsort_newindex"
    START_SITES_FLAG=""
fi

mkdir -p "$OUT_DIR"

SAMPLES=( $(ls "${READ_DIR}"/*_r1_val_1.fq.gz | xargs -I{} basename {} _r1_val_1.fq.gz) )
echo "${#SAMPLES[@]}"
SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"
READ1="${READ_DIR}/${SAMPLE}_r1_val_1.fq.gz"
READ2="${READ_DIR}/${SAMPLE}_r2_val_2.fq.gz"
SAMPLE_OUT_DIR="${OUT_DIR}/${SAMPLE}"
mkdir -p "$SAMPLE_OUT_DIR"

echo "Sample: $SAMPLE | use-start-sites: $USE_START_SITES"
xengsort classify \
    --index "$INDEX_PATH" \
    $START_SITES_FLAG \
    --fastq "$READ1" \
    --pairs "$READ2" \
    --prefix "${SAMPLE_OUT_DIR}/${SAMPLE}" \
    --mode count \
    --threads 8