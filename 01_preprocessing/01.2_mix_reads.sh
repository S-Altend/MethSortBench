#!/usr/bin/env bash
set -euo pipefail
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

DATA_DIR="${DATA_DIR}/trimmed_reads/10bp_clip_all"
MOUSE="wgbs-mouse-pancreas-organoid2"
HUMAN="wgbs-human-pancreas-organoid2"
TOTAL_READS=50000000
MIXTURE_RATIOS=("0.1" "0.2" "0.3" "0.4" "0.5" "0.6" "0.7" "0.8" "0.9")
SEEDS=(0 1 2 3 4 5)
OUT_DIR="${DATA_DIR%/trimmed_reads/10bp_clip_all}/mixtures"

mkdir -p "$OUT_DIR"

fastq_read_count() {
    zcat "$1" | awk 'END {print NR/4}'
}

HUMAN_COUNT=$(fastq_read_count "$DATA_DIR/${HUMAN}_r1_val_1.fq.gz")
MOUSE_COUNT=$(fastq_read_count "$DATA_DIR/${MOUSE}_r1_val_1.fq.gz")
echo "$MOUSE $HUMAN"
echo "Human reads: $HUMAN_COUNT"
echo "Mouse reads: $MOUSE_COUNT"


# -------- MAIN LOOP --------
OUT_SAMPLE="$OUT_DIR/${HUMAN}_${MOUSE}"
mkdir -p "$OUT_SAMPLE"

for RATIO in "${MIXTURE_RATIOS[@]}"; do
    N_HUMAN=$(printf "%.0f" "$(echo "$TOTAL_READS * $RATIO" | bc)")
    N_MOUSE=$((TOTAL_READS - N_HUMAN))

    if (( N_HUMAN > HUMAN_COUNT )) || (( N_MOUSE > MOUSE_COUNT )); then
        echo "Skipping mixture_ratio=${RATIO}: not enough reads"
        continue
    fi

    OUT_TOTAL="$OUT_SAMPLE/$TOTAL_READS"
    mkdir -p "$OUT_TOTAL"

    MIX_PCT=$(printf "%02dp" "$(echo "$RATIO * 100" | bc | cut -d'.' -f1)")

    for SEED in "${SEEDS[@]}"; do
        OUT_MIX="$OUT_TOTAL/$MIX_PCT"
        mkdir -p "$OUT_MIX"

        HUMAN_R1="$OUT_MIX/human_${SEED}_r1.fastq.gz"
        HUMAN_R2="$OUT_MIX/human_${SEED}_r2.fastq.gz"
        MOUSE_R1="$OUT_MIX/mouse_${SEED}_r1.fastq.gz"
        MOUSE_R2="$OUT_MIX/mouse_${SEED}_r2.fastq.gz"

        echo "Sampling HUMAN ($N_HUMAN reads, seed=$SEED)"
        seqkit sample -n "$N_HUMAN" -s "$SEED" "$DATA_DIR/${HUMAN}_r1_val_1.fq.gz" | gzip > "$HUMAN_R1"
        seqkit sample -n "$N_HUMAN" -s "$SEED" "$DATA_DIR/${HUMAN}_r2_val_2.fq.gz" | gzip > "$HUMAN_R2"

        echo "Sampling MOUSE ($N_MOUSE reads, seed=$SEED)"
        seqkit sample -n "$N_MOUSE" -s "$SEED" "$DATA_DIR/${MOUSE}_r1_val_1.fq.gz" | gzip > "$MOUSE_R1"
        seqkit sample -n "$N_MOUSE" -s "$SEED" "$DATA_DIR/${MOUSE}_r2_val_2.fq.gz" | gzip > "$MOUSE_R2"

        MIXED_R1="$OUT_MIX/mixed_${SEED}_r1.fastq.gz"
        MIXED_R2="$OUT_MIX/mixed_${SEED}_r2.fastq.gz"

        echo "Merging + prefixing read IDs"

        # Merge R1 (prefix @ => @human_ or @mouse_)
        {
            zcat "$HUMAN_R1" | awk 'NR%4==1 {sub(/^@/, "@human_")} {print}'
            zcat "$MOUSE_R1" | awk 'NR%4==1 {sub(/^@/, "@mouse_")} {print}'
        } | gzip > "$MIXED_R1"


        # Merge R2
        {
            zcat "$HUMAN_R2" | awk 'NR%4==1 {sub(/^@/, "@human_")} {print}'
            zcat "$MOUSE_R2" | awk 'NR%4==1 {sub(/^@/, "@mouse_")} {print}'
        } | gzip > "$MIXED_R2"

        echo "Cleaning up temporary FASTQs"
        rm -f "$HUMAN_R1" "$HUMAN_R2" "$MOUSE_R1" "$MOUSE_R2"

    done
done
