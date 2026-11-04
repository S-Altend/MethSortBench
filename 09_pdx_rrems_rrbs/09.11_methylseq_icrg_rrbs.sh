#!/bin/bash
#BSUB -J icrg_guillen_rrbs
#BSUB -n 20
#BSUB -R "rusage[mem=300GB]"
#BSUB -q highmem
#BSUB -o logs/icrg_rrbs.out
#BSUB -e logs/icrg_rrbs.err
# Pass USE_START_SITES=1 to align MspI-prefiltered reads instead of standard trimmed reads.
# Usage:
#   bsub < 09.11_methylseq_icrg_rrbs.sh               → rrbs/pipeline_icrg/
#   USE_START_SITES=1 bsub < ...                       → rrbs/pipeline_icrg_mspi/

USE_START_SITES="${USE_START_SITES:-0}"

source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

if [[ "$USE_START_SITES" == "1" ]]; then
    PIPELINE_SUFFIX="_mspi"
    INPUT="${REPO_DIR}/09_pdx_guillen_2022/methylseq_samplesheets/guillen_rrbs_icrg_mspi.csv"
    OUT_DIR="${GUILLEN_DATA_DIR}/rrbs/pipeline_icrg_mspi"
else
    PIPELINE_SUFFIX=""
    INPUT="${REPO_DIR}/09_pdx_guillen_2022/methylseq_samplesheets/guillen_rrbs_icrg.csv"
    OUT_DIR="${GUILLEN_DATA_DIR}/rrbs/pipeline_icrg"
fi

nextflow run nf-core/methylseq \
    -w "${REPO_DIR}/tmp/guillen_rrbs_icrg${PIPELINE_SUFFIX}" \
    -profile singularity \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic_GRCm38-genomic_combined.fna" \
    --aligner bwameth --use_mem2 --skip_trimming --rrbs
