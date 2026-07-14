script_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)

REPO_DIR       <- normalizePath(file.path(script_dir, ".."))
PDX_DATA_DIR   <- file.path(REPO_DIR, "data", "achinger-kawecka_2024")
pipelines_dir  <- file.path(PDX_DATA_DIR, "pipelines")

human_dir      <- file.path(pipelines_dir, "methylseq_bwameth_GRCh382", "bwameth", "deduplicated")
mouse_dir      <- file.path(pipelines_dir, "methylseq_bwameth_GRCm382", "bwameth", "deduplicated")
xenofilter_dir <- file.path(PDX_DATA_DIR, "xenofilter2")
dir.create(xenofilter_dir, recursive = TRUE, showWarnings = FALSE)

human_bams <- sort(list.files(human_dir, pattern = "\\.markdup\\.sorted\\.bam$", full.names = TRUE))

human_bam_list <- c()
mouse_bam_list <- c()
output_names   <- c()

for (human_bam in human_bams) {
  sample    <- sub("\\.markdup\\.sorted\\.bam$", "", basename(human_bam))
  mouse_bam <- file.path(mouse_dir, paste0(sample, ".markdup.sorted.bam"))

  human_bam_list <- c(human_bam_list, human_bam)
  mouse_bam_list <- c(mouse_bam_list, mouse_bam)
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
        " PDX samples -> ", xenofilter_dir)
