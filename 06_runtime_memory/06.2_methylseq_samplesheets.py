import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "helper"))
from make_samplesheet import make_samplesheet

REPO    = Path(__file__).parent.parent
OUT_DIR = Path(__file__).parent / "methylseq_samplesheets"

PAIRS = [
    ("wgbs-human-pancreas-organoid1", "wgbs-mouse-pancreas-organoid1"),
    ("wgbs-human-pancreas-organoid2", "wgbs-mouse-pancreas-organoid2"),
    ("wgbs-human-pancreas-organoid3", "wgbs-mouse-pancreas-organoid3"),
    ("wgbs-human-brca-cl1",           "wgbs-mouse-bm-hsc1"),
]

for human, mouse in PAIRS:
    for genome in ["GRCh38", "GRCm38"]:
        make_samplesheet(
            human=human,
            mouse=mouse,
            genome=genome,
            total_reads=["50000000"],
            mixtures=["60p"],
            replicates=[0, 1, 2],
            out_prefix="10p_",
            data_dir=REPO / "data" / "mixtures",
            out_dir=OUT_DIR,
        )
