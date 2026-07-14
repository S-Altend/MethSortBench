script_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)
source(file.path(script_dir, "..", "helper", "run_xenofilter.R"))

REPO_DIR <- normalizePath(file.path(script_dir, ".."))

run_xenofilter(
  human_sample   = "wgbs-human-pancreas-organoid2",
  mouse_sample   = "wgbs-mouse-pancreas-organoid2",
  xenofilter_dir = file.path(REPO_DIR, "data", "xenofilter_mm8"),
  total_counts = "10000000",
  MM_threshold = 8
)
