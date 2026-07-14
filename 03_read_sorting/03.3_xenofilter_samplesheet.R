script_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)
source(file.path(script_dir, "..", "helper", "xenofilter_samplesheet.R"))

REPO_DIR <- normalizePath(file.path(script_dir, ".."))

make_xenofilter_samplesheet(
  human_sample   = "wgbs-human-pancreas-organoid3",
  mouse_sample   = "wgbs-mouse-pancreas-organoid3",
  total_counts = c("10000000"),
  alignment_dir  = file.path(REPO_DIR, "data", "methylseq_refseq"),
  xenofilter_dir = file.path(REPO_DIR, "data", "xenofilter_mm8")
)
