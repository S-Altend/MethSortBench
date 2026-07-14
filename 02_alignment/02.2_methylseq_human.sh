#!/bin/bash
# Submit human-genome alignments for all 4 sample pairs × 10M + 50M reads.
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

PAIRS=(
    "wgbs-human-pancreas-organoid1 wgbs-mouse-pancreas-organoid1"
    "wgbs-human-pancreas-organoid2 wgbs-mouse-pancreas-organoid2"
    "wgbs-human-pancreas-organoid3 wgbs-mouse-pancreas-organoid3"
    "wgbs-human-brca-cl1 wgbs-mouse-bm-hsc1"
)

for PAIR in "${PAIRS[@]}"; do
    HUMAN=$(echo "$PAIR" | awk '{print $1}')
    MOUSE=$(echo "$PAIR" | awk '{print $2}')

    for TOTAL_READS in 10000000; do
        SAMPLE_PREFIX="${HUMAN}_${MOUSE}"
        INPUT="${REPO_DIR}/02_alignment/methylseq_samplesheets/${SAMPLE_PREFIX}_${TOTAL_READS}_${HUMAN_GENOME}.csv"
        OUTDIR="${DATA_DIR}/methylseq_refseq/${SAMPLE_PREFIX}/${TOTAL_READS}/all_human"
        WORKDIR="${DATA_DIR}/work/methylseq_refseq_${SAMPLE_PREFIX}_${TOTAL_READS}_human"

        QUEUE="highmem"

        bsub \
            -q "$QUEUE" \
            -R "rusage[mem=205GB]" \
            -n 20 \
            -J "align_${HUMAN##*-}_${TOTAL_READS}_human" \
            nextflow run nf-core/methylseq \
                -profile singularity \
                --input "$INPUT" \
                --outdir "$OUTDIR" \
                --aligner bwameth --use_mem2 --skip_trimming \
                --fasta "${REFERENCE_DIR}/GRCh38.p14-genomic.fna" \
                -w "$WORKDIR"

        echo "[$(date '+%H:%M:%S')] Submitted: ${SAMPLE_PREFIX} ${TOTAL_READS} human"
    done
done
