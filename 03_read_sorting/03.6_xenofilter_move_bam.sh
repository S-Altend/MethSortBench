#!/bin/bash

DATA_DIR="/omics/groups/OE0219/internal/altendorfer/epiproper/read_sorting_benchmark/data/xenofilter/wgbs-human-pancreas-organoid3_wgbs-mouse-pancreas-organoid3"

# Loop over all files in Filtered_bams/
for file in "${DATA_DIR}/Filtered_bams/"*; do
    filename=$(basename "$file")

    # Handle xenofileR.log separately
    if [[ "$filename" == "XenofilteR.log" ]]; then
        cp "$file" "${DATA_DIR}/../XenofilteR.log"
        continue
    fi

    # Split filename by "_"
    IFS='_' read -r human mouse total_reads mixture replicate rest <<< "$filename"

    # Extract replicate number before ".bam" or ".bam.bai"
    rep="${replicate%%.*}"

    # Create directory structure: total_reads/mixture
    dir="${DATA_DIR}/${total_reads}/${mixture}"
    mkdir -p "$dir"

    # Copy file into the new structure with proper naming
    cp "$file" "${dir}/${rep}_filtered.${file##*.}"
done
