#!/bin/bash
# Mouse reference alignment for 90% mouse / 10% human mixtures.
# Submits one LSF job per sample pair (4 jobs total).
# Required for bamcmp and XenofilteR runtime benchmark at 10p mixture.
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

TOTAL_READS="50000000"
MIXTURE="60p"

declare -A HUMAN_SAMPLES
declare -A MOUSE_SAMPLES

HUMAN_SAMPLES["organoid1"]="wgbs-human-pancreas-organoid1"
MOUSE_SAMPLES["organoid1"]="wgbs-mouse-pancreas-organoid1"

HUMAN_SAMPLES["organoid2"]="wgbs-human-pancreas-organoid2"
MOUSE_SAMPLES["organoid2"]="wgbs-mouse-pancreas-organoid2"

HUMAN_SAMPLES["organoid3"]="wgbs-human-pancreas-organoid3"
MOUSE_SAMPLES["organoid3"]="wgbs-mouse-pancreas-organoid3"

HUMAN_SAMPLES["cellline"]="wgbs-human-brca-cl1"
MOUSE_SAMPLES["cellline"]="wgbs-mouse-bm-hsc1"

for LABEL in organoid1 organoid2; do
    HUMAN="${HUMAN_SAMPLES[$LABEL]}"
    MOUSE="${MOUSE_SAMPLES[$LABEL]}"

    INPUT="${REPO_DIR}/06_runtime_memory/methylseq_samplesheets/${MIXTURE}_${HUMAN}_${MOUSE}_${TOTAL_READS}_${MOUSE_GENOME}.csv"
    OUTDIR="${DATA_DIR}/runtime_memory/pipelines/${MIXTURE}_${LABEL}_mouse"
    WORKDIR="${DATA_DIR}/runtime_memory/work/${MIXTURE}_${LABEL}_mouse"

    bsub \
        -q highmem \
        -M 205G \
        -R "rusage[mem=205G]" \
        -n 20 \
        -J "10p_${LABEL}_mouse" \
        -o "${OUTDIR}.log" \
        -e "${OUTDIR}.err" \
        nextflow run nf-core/methylseq \
            -profile singularity \
            --input "$INPUT" \
            --outdir "$OUTDIR" \
            --aligner bwameth --use_mem2 --skip_trimming \
            --fasta "${REFERENCE_DIR}/GRCm38-genomic.fna" \
            -w "$WORKDIR"

    echo "[$(date '+%H:%M:%S')] Submitted LSF job: 10p_${LABEL}_mouse"
done
