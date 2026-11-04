#!/bin/bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

ORIGIN="achinger-kawecka"
ALIGNER="bwameth"
INPUT="${REPO_DIR}/08_pdx/methylseq_samplesheets_newindex/${ORIGIN}.csv"

# Usage: bash 08.6_methylseq_bamcmp_xenofilter.sh GRCh38
#        bash 08.6_methylseq_bamcmp_xenofilter.sh GRCm38
REFERENCE="${1:?Usage: $0 GRCh38|GRCm38}"

declare -A FASTA_MAP
FASTA_MAP["${HUMAN_GENOME}"]="${REFERENCE_DIR}/GRCh38.p14-genomic.fna"
FASTA_MAP["${MOUSE_GENOME}"]="${REFERENCE_DIR}/GRCm38-genomic.fna"

FASTA="${FASTA_MAP[$REFERENCE]:?Unknown reference: $REFERENCE}"
OUT_DIR="${PDX_DATA_DIR}/pipelines/methylseq_${ALIGNER}_${REFERENCE}3"

nextflow run nf-core/methylseq \
    -w "${REPO_DIR}/tmp/achinger-kawecka_${REFERENCE}3_mem2" \
    -profile singularity \
    --input "$INPUT" \
    --outdir "$OUT_DIR" \
    --aligner "$ALIGNER" --use_mem2 \
    --skip_trimming \
    --fasta "$FASTA" \
    --run_qualimap --run_preseq
