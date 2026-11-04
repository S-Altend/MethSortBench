#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

INPUT="${REPO_DIR}/08_pdx_wgbs/methylseq_samplesheets_newindex/achinger-kawecka.csv"
OUT_DIR="${DATA_DIR}/pipeline_pdx_icrg2"

nextflow run nf-core/methylseq \
    -w "${REPO_DIR}/tmp/achinger-kawecka_icrg2_mem2" \
    -profile singularity \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic_GRCm38-genomic_combined.fna" \
    --aligner bwameth --use_mem2 --skip_trimming
