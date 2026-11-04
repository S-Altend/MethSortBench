#!/bin/bash
#BSUB -J methylseq_guillen_rrbs
#BSUB -n 20
#BSUB -R "rusage[mem=201GB]"
#BSUB -q highmem
#BSUB -o logs/methylseq_rrbs_%J.out
#BSUB -e logs/methylseq_rrbs_%J.err
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

# Usage:
#   bsub < 09.14_methylseq_human_rrbs.sh                        # human, no MspI
#   GENOME=mouse bsub < 09.14_methylseq_human_rrbs.sh           # mouse, no MspI
#   USE_START_SITES=1 bsub < 09.14_methylseq_human_rrbs.sh      # human, MspI
#   GENOME=mouse USE_START_SITES=1 bsub < 09.14_methylseq_human_rrbs.sh
GENOME="${GENOME:-human}"
USE_START_SITES="${USE_START_SITES:-0}"

if [[ "$GENOME" == "mouse" ]]; then
    FASTA="${REFERENCE_DIR}/GRCm38-genomic.fna"
else
    FASTA="${REFERENCE_DIR}/GRCh38.p14-genomic.fna"
fi

if [[ "$USE_START_SITES" == "1" ]]; then
    INPUT="${REPO_DIR}/09_pdx_guillen_2022/methylseq_samplesheets_newindex/guillen_rrbs_icrg_mspi.csv"
    LABEL="_mspi"
else
    INPUT="${REPO_DIR}/09_pdx_guillen_2022/methylseq_samplesheets_newindex/guillen_rrbs.csv"
    LABEL=""
fi

mkdir -p "${REPO_DIR}/09_pdx_guillen_2022/logs"

OUT_DIR="${GUILLEN_DATA_DIR}/rrbs/pipelines/pipeline_${GENOME}${LABEL}"

nextflow run nf-core/methylseq \
    -w "${REPO_DIR}/tmp/guillen_rrbs_${LABEL}_${GENOME}" \
    -profile singularity \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --fasta "$FASTA" \
    --aligner bwameth --use_mem2 --skip_trimming --rrbs
