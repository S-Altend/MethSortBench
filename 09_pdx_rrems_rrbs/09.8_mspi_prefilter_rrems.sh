#!/usr/bin/env bash
# Prefilter RREMS trimmed reads to MspI-eligible reads before xengsort.
#BSUB -J mspi_prefilter_rrems[1-20]
#BSUB -n 4
#BSUB -M 16000
#BSUB -R "rusage[mem=16000]"
#BSUB -o logs/mspi_prefilter_rrems_%I.out
#BSUB -e logs/mspi_prefilter_rrems_%I.err
#BSUB -q long

set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

READ_DIR="${GUILLEN_DATA_DIR}/rrems/trimmed_reads"
OUT_DIR="${GUILLEN_DATA_DIR}/rrems/mspi_prefiltered"
mkdir -p "$OUT_DIR"
mkdir -p "${REPO_DIR}/09_pdx_rrems_rrbs/logs"

SAMPLES=( $(ls "${READ_DIR}"/*_r1_val_1.fq.gz | xargs -I{} basename {} _r1_val_1.fq.gz) )
SAMPLE="${SAMPLES[$((LSB_JOBINDEX - 1))]}"
READ1="${READ_DIR}/${SAMPLE}_r1_val_1.fq.gz"
READ2="${READ_DIR}/${SAMPLE}_r2_val_2.fq.gz"
OUT_R1="${OUT_DIR}/${SAMPLE}_r1_mspi.fq.gz"
OUT_R2="${OUT_DIR}/${SAMPLE}_r2_mspi.fq.gz"

echo "Sample: $SAMPLE"
echo "Input R1: $READ1"
echo "Input R2: $READ2"

# Use a named pipe to process R1 and R2 in sync.
# For each 4-line block: keep pair if R1 sequence starts with CGG or TGG.
TMPDIR_LOCAL=$(mktemp -d)
trap "rm -rf $TMPDIR_LOCAL" EXIT

FIFO_R1="${TMPDIR_LOCAL}/r1.fifo"
FIFO_R2="${TMPDIR_LOCAL}/r2.fifo"
mkfifo "$FIFO_R1" "$FIFO_R2"

paste - - - - < <(zcat "$READ1") \
    | paste - <(zcat "$READ2" | paste - - - -) \
    | awk -F'\t' '
        {
            split($0, a, "\t")
            # a[1..4] = R1 fields, a[5..8] = R2 fields
            if (a[2] ~ /^[CT]GG/) {
                print a[1] "\t" a[2] "\t" a[3] "\t" a[4]
                print a[5] "\t" a[6] "\t" a[7] "\t" a[8]
            }
        }
    ' \
    | tee \
        >(awk 'NR%2==1 {gsub(/\t/,"\n"); print}' | gzip -c > "$OUT_R1") \
        >(awk 'NR%2==0 {gsub(/\t/,"\n"); print}' | gzip -c > "$OUT_R2") \
        > /dev/null

TOTAL=$(zcat "$READ1" | awk 'NR%4==2' | wc -l)
KEPT=$(zcat "$OUT_R1"  | awk 'NR%4==2' | wc -l)
PCT=$(awk "BEGIN {printf \"%.2f\", 100*${KEPT}/${TOTAL}}")
echo "Total pairs: ${TOTAL} | MspI-eligible: ${KEPT} (${PCT}%) | Excluded: $((TOTAL - KEPT))"
