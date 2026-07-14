#!/usr/bin/env Rscript
# Submit: bsub -J xenofilter_pdx2[1-8] -n 1 -M 80000 -R "rusage[mem=80000]" -q long \
#         -o logs/xenofilter2_%I.out -e logs/xenofilter2_%I.err Rscript 08.11b_xenofilter.R

library("XenofilteR")
library("BiocParallel")

script_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)

REPO_DIR       <- normalizePath(file.path(script_dir, ".."))
xenofilter_dir <- file.path(REPO_DIR, "data", "achinger-kawecka_2024", "xenofilter2")

samples_matrix <- read.csv(file.path(xenofilter_dir, "samples_matrix.csv"))
output_names   <- as.vector(unlist(read.csv(file.path(xenofilter_dir, "output_list.csv"))))

job_index <- as.integer(Sys.getenv("LSB_JOBINDEX", unset = "1"))
row       <- samples_matrix[job_index, , drop = FALSE]
out_name  <- output_names[job_index]

cat("Processing sample:", basename(out_name), "\n")

dir.create(out_name, recursive = TRUE, showWarnings = FALSE)

XenofilteR(
  row,
  destination.folder = out_name,
  output.names       = basename(out_name),
  bp.param           = SnowParam(workers = 1, type = "SOCK")
)
