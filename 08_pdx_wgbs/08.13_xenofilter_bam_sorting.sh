#!/usr/bin/env bash
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

PDX_PIPELINES="${PDX_DATA_DIR}/pipelines"
THREADS=16

for GENOME in "${HUMAN_GENOME}" "${MOUSE_GENOME}"; do
    BAM_DIR="${PDX_PIPELINES}/methylseq_bwameth_${GENOME}/bwameth/deduplicated"

    for BAM in "${BAM_DIR}"/*.markdup.sorted.bam; do
        SAMPLE=$(basename "$BAM" .markdup.sorted.bam)
        OUT="${BAM_DIR}/${SAMPLE}.coord.sorted.bam"

        if [[ -f "${OUT}" ]]; then
            echo "Skipping ${GENOME}: ${SAMPLE} (already done)"
            continue
        fi
        echo "Coord-sorting ${GENOME}: ${SAMPLE}"
        samtools sort --threads "${THREADS}" -o "${OUT}" "${BAM}"
        samtools index "${OUT}"
    done
done

echo "Done."
