#!/usr/bin/env bash
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

OUTPUT_DIR="${DATA_DIR}/xengsort_newindex"
INDEX_PATH="${OUTPUT_DIR}/converted_index"
mkdir -p "$OUTPUT_DIR"

GENOME_HUMAN="GRCh38.p14-genomic.fna"
GENOME_MOUSE="GRCm38-genomic.fna"

echo "Indexing: ${REFERENCE_DIR}/${GENOME_HUMAN} + ${REFERENCE_DIR}/${GENOME_MOUSE}"
echo "Index path: $INDEX_PATH"

xengsort index \
    --index "$INDEX_PATH" \
    -H "${REFERENCE_DIR}/${GENOME_MOUSE}" \
    -G "${REFERENCE_DIR}/${GENOME_HUMAN}" \
    -n 9_000_000_000 \
    --bisulfite \
    -k 29
