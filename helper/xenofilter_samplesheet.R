# Helper: generate XenofilteR input CSVs from the benchmark directory tree.

make_xenofilter_samplesheet <- function(
    human_sample,
    mouse_sample,
    alignment_dir,
    xenofilter_dir,
    total_counts = c("50000000"),
    mixtures     = c("10p", "20p", "30p", "40p", "50p", "60p", "70p", "80p", "90p"),
    replicates   = c(0, 1, 2, 3, 4, 5),
    human_genome = "GRCh38",
    mouse_genome = "GRCm38"
) {
  sample_prefix <- paste(human_sample, mouse_sample, sep = "_")

  human_bam_list <- c()
  mouse_bam_list <- c()
  output_names   <- c()

  for (total_count in total_counts) {
    for (mixture in mixtures) {
      for (replicate in replicates) {
        print(paste(total_count, mixture, replicate))

        bam_dir   <- file.path(alignment_dir, sample_prefix, total_count, mixture)
        human_bam <- file.path(bam_dir, paste0(paste("mixed", replicate, human_genome, sep = "_"), ".coord.sorted.bam"))
        mouse_bam <- file.path(bam_dir, paste0(paste("mixed", replicate, mouse_genome, sep = "_"), ".coord.sorted.bam"))

        human_bam_list <- c(human_bam_list, human_bam)
        mouse_bam_list <- c(mouse_bam_list, mouse_bam)

        output_dir <- file.path(xenofilter_dir, sample_prefix, total_count, mixture)
        if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

        output_name <- file.path(xenofilter_dir, paste(sample_prefix, total_count, mixture, replicate, sep = "_"))
        output_names <- c(output_names, output_name)
      }
    }
  }

  bam_df <- data.frame(
    human_bam = human_bam_list,
    mouse_bam = mouse_bam_list,
    stringsAsFactors = FALSE
  )

  write.csv(bam_df,
    file.path(xenofilter_dir, paste(sample_prefix, total_counts, "samples_matrix.csv", sep = "_")),
    row.names = FALSE)
  write.csv(output_names,
    file.path(xenofilter_dir, paste(sample_prefix, total_counts, "output_list.csv", sep = "_")),
    row.names = FALSE)

  message("[OK] Wrote samplesheet for ", sample_prefix, " -> ", xenofilter_dir)
}
