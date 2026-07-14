#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

bamcmp_dir="${REPO_DIR}/tmp/bamcmp2"
out_base="${REPO_DIR}/tmp/bamcmp2_results"
method="bamcmp"

for sample_dir in "$bamcmp_dir"/*/; do
    sample=$(basename "$sample_dir")
    out_dir="${out_base}/${sample}"
    mkdir -p "$out_dir"

    echo "Evaluating ${sample}..."

    count_bam() {
        local f="$1"
        if [[ ! -s "$f" ]]; then echo 0; return; fi
        samtools view -F 0x900 -c "$f"
    }

    human_only=$(count_bam "${sample_dir}${sample}.humanOnly.bam")
    human_better=$(count_bam "${sample_dir}${sample}.humanBetter.bam")
    mouse_only=$(count_bam "${sample_dir}${sample}.mouseOnly.bam")
    mouse_better=$(count_bam "${sample_dir}${sample}.mouseBetter.bam")

    echo -e "Category\tReads\tSample\tMethod" > "${out_dir}/evaluation.tsv"
    echo -e "humanOnly\t${human_only}\t${sample}\t${method}" >> "${out_dir}/evaluation.tsv"
    echo -e "humanBetter\t${human_better}\t${sample}\t${method}" >> "${out_dir}/evaluation.tsv"
    echo -e "mouseOnly\t${mouse_only}\t${sample}\t${method}" >> "${out_dir}/evaluation.tsv"
    echo -e "mouseBetter\t${mouse_better}\t${sample}\t${method}" >> "${out_dir}/evaluation.tsv"

    echo "Saved to ${out_dir}/evaluation.tsv"
done
