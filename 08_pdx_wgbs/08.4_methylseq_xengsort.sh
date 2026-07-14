#!/usr/bin/env bash
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

INPUT="${REPO_DIR}/08_pdx/methylseq_samplesheets/achinger-kawecka_xengsort_graft.csv"
OUT_DIR="${PDX_DATA_DIR}/pipelines/methylseq_bwameth_xengsort_${HUMAN_GENOME}"

nextflow run nf-core/methylseq \
    -w "${REPO_DIR}/tmp/achinger-kawecka_xengsort2_${HUMAN_GENOME}_mem2" \
    -profile singularity \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --aligner bwameth --use_mem2 --skip_trimming \
    --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic.fna"
