#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

# HUMAN="wgbs-human-brca-cl1"
# MOUSE="wgbs-mouse-bm-hsc1"
HUMAN="wgbs-human-pancreas-organoid3"
MOUSE="wgbs-mouse-pancreas-organoid3"
TOTAL_READS="50000000"
GENOME="${HUMAN_GENOME}"
INPUT="${REPO_DIR}/06_runtime_memory/methylseq_samplesheets/${HUMAN}_${MOUSE}_${TOTAL_READS}_${GENOME}.csv"
OUT_DIR="${DATA_DIR}/runtime_memory/combined_organoid3"

nextflow run nf-core/methylseq \
    -profile singularity \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --aligner bwameth --use_mem2 --skip_trimming \
    --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic_GRCm38-genomic_combined.fna"
