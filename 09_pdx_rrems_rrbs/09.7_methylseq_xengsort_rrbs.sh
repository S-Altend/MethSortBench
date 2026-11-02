#!/bin/bash
#BSUB -J methylseq_guillen_xengsort_rrbs
#BSUB -n 20
#BSUB -R "rusage[mem=251GB]"
#BSUB -q highmem
#BSUB -o logs/logs_newindex/methylseq_xengsort_rrbs.out
#BSUB -e logs/logs_newindex/methylseq_xengsort_rrbs.err
# Pass USE_START_SITES=1 to align xengsort MspI-prefiltered graft reads instead of standard graft reads.
# Usage:
#   bsub < 09.7_methylseq_xengsort_rrbs.sh               → rrbs/pipeline_xengsort/
#   USE_START_SITES=1 bsub < ...                          → rrbs/pipeline_xengsort_mspi/

USE_START_SITES="${USE_START_SITES:-0}"

source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"


if [[ "$USE_START_SITES" == "1" ]]; then
    PIPELINE_SUFFIX="_mspi"
    INPUT="${REPO_DIR}/09_pdx_rrems_rrbs/methylseq_samplesheets_newindex/guillen_rrbs_xengsort_graft_mspi.csv"
    OUT_DIR="${GUILLEN_DATA_DIR}/rrbs/pipeline_xengsort_mspi_newindex"
else
    PIPELINE_SUFFIX=""
    INPUT="${REPO_DIR}/09_pdx_rrems_rrbs/methylseq_samplesheets_newindex/guillen_rrbs_xengsort_graft.csv"
    OUT_DIR="${GUILLEN_DATA_DIR}/rrbs/pipeline_xengsort_newindex"
fi

nextflow run nf-core/methylseq \
    -w "${REPO_DIR}/tmp/guillen_rrbs_xengsort${PIPELINE_SUFFIX}" \
    -profile singularity \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic.fna" \
    --aligner bwameth --use_mem2 --skip_trimming --rrbs
