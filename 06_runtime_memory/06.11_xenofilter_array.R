#!/usr/bin/env Rscript
#BSUB -J xenofilter_runmem[1-12]
#BSUB -n 8
#BSUB -M 80G
#BSUB -R "rusage[mem=80G]"
#BSUB -q long
#BSUB -o logs/xenofilter_%I.out
#BSUB -e logs/xenofilter_%I.err

library("XenofilteR")
library("BiocParallel")

script_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)

REPO_DIR <- normalizePath(file.path(script_dir, ".."))

# 4 sample pairs × 3 replicates = 12 jobs
HUMAN_SAMPLES <- c(
  "wgbs-human-pancreas-organoid1",
  "wgbs-human-pancreas-organoid2",
  "wgbs-human-pancreas-organoid3",
  "wgbs-human-brca-cl1"
)
MOUSE_SAMPLES <- c(
  "wgbs-mouse-pancreas-organoid1",
  "wgbs-mouse-pancreas-organoid2",
  "wgbs-mouse-pancreas-organoid3",
  "wgbs-mouse-bm-hsc1"
)

job_index  <- as.integer(Sys.getenv("LSB_JOBINDEX", unset = "1"))
idx        <- job_index - 1L
pair_idx   <- idx %/% 3L + 1L   # 1-based index into sample vectors
replicate  <- idx  %% 3L        # 0-based replicate number

human_sample  <- HUMAN_SAMPLES[pair_idx]
mouse_sample  <- MOUSE_SAMPLES[pair_idx]
sample_prefix <- paste(human_sample, mouse_sample, sep = "_")
total_count   <- "50000000"

xenofilter_dir <- file.path(REPO_DIR, "data", "runtime_memory", "xenofilter")

samples_matrix <- read.csv(
  file.path(xenofilter_dir, paste(sample_prefix, total_count, "samples_matrix.csv", sep = "_"))
)
output_names <- as.vector(unlist(read.csv(
  file.path(xenofilter_dir, paste(sample_prefix, total_count, "output_list.csv", sep = "_"))
)))

# Each samplesheet has 3 rows (replicates 0, 1, 2); pick the one for this job
row_idx  <- replicate + 1L   # R is 1-based
row      <- samples_matrix[row_idx, , drop = FALSE]
out_name <- output_names[row_idx]

cat("Sample:", sample_prefix, ", replicate:", replicate, "\n")

dir.create(out_name, recursive = TRUE, showWarnings = FALSE)

XenofilteR(
  row,
  destination.folder = out_name,
  output.names       = basename(out_name),
  bp.param           = SnowParam(workers = 1, type = "SOCK"),
  MM_threshold = 8
)
