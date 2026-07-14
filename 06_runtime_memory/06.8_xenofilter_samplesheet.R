script_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)
source(file.path(script_dir, "..", "helper", "xenofilter_samplesheet.R"))

REPO_DIR <- normalizePath(file.path(script_dir, ".."))

PAIRS <- list(
  list(human = "wgbs-human-pancreas-organoid1", mouse = "wgbs-mouse-pancreas-organoid1"),
  list(human = "wgbs-human-pancreas-organoid2", mouse = "wgbs-mouse-pancreas-organoid2"),
  list(human = "wgbs-human-pancreas-organoid3", mouse = "wgbs-mouse-pancreas-organoid3"),
  list(human = "wgbs-human-brca-cl1",           mouse = "wgbs-mouse-bm-hsc1")
)

for (pair in PAIRS) {
  make_xenofilter_samplesheet(
    human_sample   = pair$human,
    mouse_sample   = pair$mouse,
    alignment_dir  = file.path(REPO_DIR, "data", "methylseq_refseq"),
    xenofilter_dir = file.path(REPO_DIR, "data", "runtime_memory", "xenofilter"),
    mixtures       = c("60p"),
    replicates     = c(0, 1, 2)
  )
}
