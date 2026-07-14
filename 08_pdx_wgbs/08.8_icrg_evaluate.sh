#!/usr/bin/env bash
source "/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/config.sh"

data_dir="${DATA_DIR}/achinger-kawecka_2024/pipelines/pipeline_pdx_icrg2/bwameth/deduplicated"
out_base="${REPO_DIR}/08_pdx/results/icrg_wgbs"

for bam in "$data_dir"/*.markdup.sorted.bam; do
    sample=$(basename "$bam" .markdup.sorted.bam)
    out_dir="${out_base}/${sample}"
    mkdir -p "$out_dir"

    echo "Processing ${sample}..."

    # -F 0x904: exclude unmapped, secondary, supplementary
    human_assigned=$(samtools view -F 0x904 --threads 16 "$bam" | awk '$3 !~ /^m\./ {count++} END{print count+0}')
    mouse_assigned=$(samtools view -F 0x904 --threads 16 "$bam" | awk '$3 ~ /^m\./ {count++} END{print count+0}')

    # -F 0x900 -f 0x4: unmapped only
    unmapped=$(samtools view -F 0x900 -f 0x4 --threads 16 "$bam" | wc -l)

    echo -e "Category\tReads\tSample\tMethod" > "${out_dir}/evaluation.tsv"
    echo -e "human\t${human_assigned}\t${sample}\tICRG"   >> "${out_dir}/evaluation.tsv"
    echo -e "mouse\t${mouse_assigned}\t${sample}\tICRG"   >> "${out_dir}/evaluation.tsv"
    echo -e "unmapped\t${unmapped}\t${sample}\tICRG"      >> "${out_dir}/evaluation.tsv"

    echo "Saved output to ${out_dir}/evaluation.tsv"
done
