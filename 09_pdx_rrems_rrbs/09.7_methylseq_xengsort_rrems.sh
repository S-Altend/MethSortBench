#!/bin/bash
#BSUB -J methylseq_guillen_xengsort_rrems
#BSUB -n 20
#BSUB -R "rusage[mem=251GB]"
#BSUB -q highmem
#BSUB -o logs/logs_newindex/methylseq_xengsort_rrems.out
#BSUB -e logs/logs_newindex/methylseq_xengsort_rrems.err
# Pass USE_START_SITES=1 to align xengsort MspI-prefiltered graft reads instead of standard graft reads.
# Usage:
#   bsub < 09.7_methylseq_xengsort_rrems.sh              → rrems/pipeline_xengsort/
#   USE_START_SITES=1 bsub < ...                          → rrems/pipeline_xengsort_mspi/

USE_START_SITES="${USE_START_SITES:-0}"

source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"


if [[ "$USE_START_SITES" == "1" ]]; then
    INPUT="${REPO_DIR}/09_pdx_rrems_rrbs/methylseq_samplesheets_newindex/guillen_rrems_xengsort_graft_mspi.csv"
    OUT_DIR="${GUILLEN_DATA_DIR}/rrems/pipeline_xengsort_mspi_newindex"
else
    INPUT="${REPO_DIR}/09_pdx_rrems_rrbs/methylseq_samplesheets_newindex/guillen_rrems_xengsort_graft.csv"
    OUT_DIR="${GUILLEN_DATA_DIR}/rrems/pipeline_xengsort_newindex"
fi

nextflow run nf-core/methylseq \
    -w "${REPO_DIR}/tmp/guillen_rrems_xengsort${USE_START_SITES:+_mspi}" \
    -profile singularity \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic.fna" \
    --aligner bwameth --use_mem2 --skip_trimming --rrbs
