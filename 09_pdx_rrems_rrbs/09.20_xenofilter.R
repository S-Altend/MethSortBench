#!/usr/bin/env Rscript
# Submit (rrbs, 11 samples):
#   ASSAY=rrbs bsub -J guillen_xenofilter[1-11] -n 1 -R "rusage[mem=80GB]" -q long -o logs/xenofilter_rrbs_%I.out -e logs/xenofilter_rrbs_%I.err Rscript 09.20_xenofilter.R
#
# Submit (rrbs mspi, 11 samples):
#   ASSAY=rrbs USE_START_SITES=1 bsub -J guillen_xenofilter[1-11] -n 1 -R "rusage[mem=80GB]" -q long -o logs/xenofilter_rrbs_mspi_%I.out -e logs/xenofilter_rrbs_mspi_%I.err Rscript 09.20_xenofilter.R
#
# Submit (rrems, 20 samples):
#   ASSAY=rrems bsub -J guillen_xenofilter[1-20] -n 1 -R "rusage[mem=80GB]" -q long -o logs/xenofilter_rrems_%I.out -e logs/xenofilter_rrems_%I.err Rscript 09.20_xenofilter.R
#
# Submit (rrems mspi, 20 samples):
#   ASSAY=rrems USE_START_SITES=1 bsub -J guillen_xenofilter[1-20] -n 1 -R "rusage[mem=80GB]" -q long -o logs/xenofilter_rrems_mspi_%I.out -e logs/xenofilter_rrems_mspi_%I.err Rscript 09.20_xenofilter.R

library("XenofilteR")
library("BiocParallel")

script_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)

REPO_DIR         <- normalizePath(file.path(script_dir, ".."))
GUILLEN_DATA_DIR <- file.path(REPO_DIR, "data", "guillen_2022")

assay           <- Sys.getenv("ASSAY", unset = "rrbs")
use_start_sites <- Sys.getenv("USE_START_SITES", unset = "0")
label           <- if (use_start_sites == "1") "_mspi" else ""

xenofilter_dir <- file.path(GUILLEN_DATA_DIR, assay, paste0("xenofilter", label))

samples_matrix <- read.csv(file.path(xenofilter_dir, "samples_matrix.csv"))
output_names   <- as.vector(unlist(read.csv(file.path(xenofilter_dir, "output_list.csv"))))

job_index <- as.integer(Sys.getenv("LSB_JOBINDEX", unset = "1"))

if (job_index > nrow(samples_matrix)) {
  cat("Index", job_index, "out of range (", nrow(samples_matrix), "samples), skipping.\n")
  quit(status = 0)
}

row      <- samples_matrix[job_index, , drop = FALSE]
out_name <- output_names[job_index]

cat("Sample:", basename(out_name), "\n")

dir.create(out_name, recursive = TRUE, showWarnings = FALSE)

XenofilteR(
  row,
  destination.folder = out_name,
  output.names       = basename(out_name),
  bp.param           = SnowParam(workers = 1, type = "SOCK")
)
