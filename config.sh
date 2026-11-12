#!/bin/bash
# Shared configuration for the read-sorting benchmark.
# Sourced at the top of each script:
#   source "$(dirname "$0")/../config.sh"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${REPO_DIR}/data"
ALIGNMENT_DIR="${DATA_DIR}/methylseq_refseq"
REFERENCE_DIR="${DATA_DIR}/reference_genomes"   # symlink → epiproper_data/reference_genomes
PDX_DATA_DIR="${DATA_DIR}/achinger-kawecka_2024" # reads/trimmed_reads/xengsort_raw are symlinks to odcf
GUILLEN_DATA_DIR="${DATA_DIR}/guillen_2022" # reads/trimmed_reads/xengsort_raw are symlinks to odcf

# ---------------------------------------------------------------------------
# Genome labels
# ---------------------------------------------------------------------------
HUMAN_GENOME="GRCh38"
MOUSE_GENOME="GRCm38"

# ---------------------------------------------------------------------------
# Benchmark loop parameters 
# ---------------------------------------------------------------------------
TOTAL_COUNTS=("10000000" "50000000")
MIXTURES=("10p" "20p" "30p" "40p" "50p" "60p" "70p" "80p" "90p")
REPLICATES=("0" "1" "2" "3" "4" "5")

# ---------------------------------------------------------------------------
# All sample pairs for array jobs — index-parallel human/mouse arrays.
# Usage in scripts:
#   read -r HUMAN MOUSE <<< "${SAMPLE_PAIRS[$IDX]}"
# ---------------------------------------------------------------------------
SAMPLE_PAIRS=(
    "wgbs-human-brca-cl1 wgbs-mouse-bm-hsc1"
    "wgbs-human-pancreas-organoid1 wgbs-mouse-pancreas-organoid1"
    "wgbs-human-pancreas-organoid2 wgbs-mouse-pancreas-organoid2"
    "wgbs-human-pancreas-organoid3 wgbs-mouse-pancreas-organoid3"
)
