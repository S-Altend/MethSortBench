#!/bin/bash
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

TOTAL_READS="50000000"
GENOME="${HUMAN_GENOME}"

declare -A HUMAN_SAMPLES
declare -A MOUSE_SAMPLES

HUMAN_SAMPLES["cellline"]="wgbs-human-brca-cl1"
MOUSE_SAMPLES["cellline"]="wgbs-mouse-bm-hsc1"
HUMAN_SAMPLES["organoid1"]="wgbs-human-pancreas-organoid1"
MOUSE_SAMPLES["organoid1"]="wgbs-mouse-pancreas-organoid1"
HUMAN_SAMPLES["organoid2"]="wgbs-human-pancreas-organoid2"
MOUSE_SAMPLES["organoid2"]="wgbs-mouse-pancreas-organoid2"
HUMAN_SAMPLES["organoid3"]="wgbs-human-pancreas-organoid3"
MOUSE_SAMPLES["organoid3"]="wgbs-mouse-pancreas-organoid3"

for LABEL in cellline organoid1 organoid2 organoid3; do
    HUMAN="${HUMAN_SAMPLES[$LABEL]}"
    MOUSE="${MOUSE_SAMPLES[$LABEL]}"
    SAMPLE_PREFIX="${HUMAN}_${MOUSE}"
    INPUT="${REPO_DIR}/06_runtime_memory/methylseq_samplesheets/xengsort_graft_${SAMPLE_PREFIX}_${TOTAL_READS}_${GENOME}.csv"
    OUTDIR="${DATA_DIR}/runtime_memory/pipelines/xengsort_${LABEL}"
    WORKDIR="${DATA_DIR}/runtime_memory/work/xengsort_${LABEL}"

    bsub \
        -q highmem \
        -R "rusage[mem=205GB]" \
        -n 12 \
        -J "methylseq_xengsort_${LABEL}" \
        -o "${REPO_DIR}/06_runtime_memory/logs/xengsort_${LABEL}.out" \
        -e "${REPO_DIR}/06_runtime_memory/logs/xengsort_${LABEL}.err" \
        nextflow run nf-core/methylseq \
            -profile singularity \
            --input "$INPUT" \
            --outdir "$OUTDIR" \
            --aligner bwameth --use_mem2 --skip_trimming \
            --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic.fna" \
            -work-dir "$WORKDIR"

    echo "[$(date '+%H:%M:%S')] Submitted: methylseq_xengsort_${LABEL}"
done
