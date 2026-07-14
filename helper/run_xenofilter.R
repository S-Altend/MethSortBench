# Helper: run XenofilteR using the CSVs produced by make_xenofilter_samplesheet().


library("XenofilteR")
library("BiocParallel")

run_xenofilter <- function(
    human_sample,
    mouse_sample,
    xenofilter_dir,
    total_counts = "50000000",
    MM_threshold = 8
) {
  sample_prefix <- paste(human_sample, mouse_sample, sep = "_")
  bp.param      <- SnowParam(workers = 1, type = "SOCK")

  sample_list <- read.csv(
    file.path(xenofilter_dir, paste(sample_prefix, total_counts, "samples_matrix.csv", sep = "_"))
  )
  output_names <- as.vector(unlist(read.csv(
    file.path(xenofilter_dir, paste(sample_prefix, total_counts, "output_list.csv", sep = "_"))
  )))

  XenofilteR(
    sample_list,
    destination.folder = file.path(xenofilter_dir, sample_prefix),
    output.names       = output_names,
    bp.param           = bp.param,
    MM_threshold       = MM_threshold
  )
}
