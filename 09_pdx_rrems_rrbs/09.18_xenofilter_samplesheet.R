#!/usr/bin/env Rscript
# Usage:
#   Rscript 09.17_xenofilter_samplesheet.R
#   ASSAY=rrems Rscript 09.17_xenofilter_samplesheet.R
#   ASSAY=rrbs USE_START_SITES=1 Rscript 09.17_xenofilter_samplesheet.R
#   ASSAY=rrems USE_START_SITES=1 Rscript 09.17_xenofilter_samplesheet.R

script_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)

REPO_DIR         <- normalizePath(file.path(script_dir, ".."))
GUILLEN_DATA_DIR <- file.path(REPO_DIR, "data", "guillen_2022")

assay           <- Sys.getenv("ASSAY", unset = "rrbs")
use_start_sites <- Sys.getenv("USE_START_SITES", unset = "0")
label           <- if (use_start_sites == "1") "_mspi" else ""

human_dir <- file.path(GUILLEN_DATA_DIR, assay, "pipelines",
                       paste0("pipeline_human", label), "bwameth", "alignments")
mouse_dir <- file.path(GUILLEN_DATA_DIR, assay, "pipelines",
                       paste0("pipeline_mouse", label), "bwameth", "alignments")

xenofilter_dir <- file.path(GUILLEN_DATA_DIR, assay, paste0("xenofilter", label))
dir.create(xenofilter_dir, recursive = TRUE, showWarnings = FALSE)

human_bams <- sort(list.files(human_dir, pattern = "\\.coord\\.sorted\\.bam$", full.names = TRUE))

if (length(human_bams) == 0) {
  stop("No coord.sorted.bam files found in: ", human_dir)
}

human_bam_list <- c()
mouse_bam_list <- c()
output_names   <- c()

for (human_bam in human_bams) {
  sample <- sub("\\.coord\\.sorted\\.bam$", "", basename(human_bam))

  human_coord <- human_bam
  mouse_coord <- file.path(mouse_dir, paste0(sample, ".coord.sorted.bam"))

  human_bam_list <- c(human_bam_list, human_coord)
  mouse_bam_list <- c(mouse_bam_list, mouse_coord)
  output_names   <- c(output_names, file.path(xenofilter_dir, sample))
}

bam_df <- data.frame(human_bam = human_bam_list, mouse_bam = mouse_bam_list,
                     stringsAsFactors = FALSE)

write.csv(bam_df,
          file.path(xenofilter_dir, "samples_matrix.csv"),
          row.names = FALSE)
write.csv(data.frame(x = output_names),
          file.path(xenofilter_dir, "output_list.csv"),
          row.names = FALSE)

message("[OK] Wrote XenofilteR samplesheet for ", length(human_bam_list),
        " samples (ASSAY=", assay, ", LABEL=", label, ") -> ", xenofilter_dir)
