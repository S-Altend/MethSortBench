#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

HUMAN="wgbs-human-pancreas-organoid3"
MOUSE="wgbs-mouse-pancreas-organoid3"
# HUMAN="wgbs-human-brca-cl1"
# MOUSE="wgbs-mouse-bm-hsc1"
TOTAL_COUNT="10000000"
INPUT="${REPO_DIR}/04_icrg/methylseq_samplesheets/${HUMAN}_${MOUSE}_${TOTAL_COUNT}_combined.csv"
OUT_DIR="${DATA_DIR}/methylseq_10M_organoid3_icrg"

nextflow run nf-core/methylseq \
    -profile singularity \
    -w "${REPO_DIR}/tmp/methylseq_10M_organoid3_icrg" \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic_GRCm38-genomic_combined.fna" \
    --aligner bwameth --use_mem2 --skip_trimming
