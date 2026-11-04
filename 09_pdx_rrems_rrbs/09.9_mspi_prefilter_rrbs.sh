#!/usr/bin/env bash
# Prefilter RRBS trimmed reads to MspI-eligible reads before xengsort.
#BSUB -J mspi_prefilter[1-11]
#BSUB -n 4
#BSUB -M 16000
#BSUB -R "rusage[mem=16000]"
#BSUB -o logs/mspi_prefilter_%I.out
#BSUB -e logs/mspi_prefilter_%I.err
#BSUB -q long

set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

READ_DIR="${GUILLEN_DATA_DIR}/rrbs/trimmed_reads"
OUT_DIR="${GUILLEN_DATA_DIR}/rrbs/mspi_prefiltered"
mkdir -p "$OUT_DIR"
mkdir -p "${REPO_DIR}/09_pdx_rrems_rrbs/logs"

SAMPLES=( $(ls "${READ_DIR}"/*_r1_trimmed.fq.gz | xargs -I{} basename {} _r1_trimmed.fq.gz) )
SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"
READ1="${READ_DIR}/${SAMPLE}_r1_trimmed.fq.gz"
OUT_FQ="${OUT_DIR}/${SAMPLE}_r1_mspi.fq.gz"

echo "Sample: $SAMPLE"
echo "Input:  $READ1"
echo "Output: $OUT_FQ"

# Keep 4-line FASTQ blocks where sequence line (NR%4==2) starts with CGG or TGG.
zcat "$READ1" \
    | awk '
        { a[NR%4] = $0 }
        NR%4==0 {
            if (a[2] ~ /^[CT]GG/) {
                print a[1]
                print a[2]
                print a[3]
                print a[0]
            }
        }
    ' \
    | gzip -c \
    > "$OUT_FQ"

TOTAL=$(zcat "$READ1" | awk 'NR%4==2' | wc -l)
KEPT=$(zcat "$OUT_FQ"  | awk 'NR%4==2' | wc -l)
PCT=$(awk "BEGIN {printf \"%.2f\", 100*${KEPT}/${TOTAL}}")
echo "Total reads: ${TOTAL} | MspI-eligible: ${KEPT} (${PCT}%) | Excluded: $((TOTAL - KEPT))"
