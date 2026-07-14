import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "helper"))
from make_samplesheet import make_samplesheet

REPO = Path(__file__).parent.parent

make_samplesheet(
    human="wgbs-human-brca-cl1",
    mouse="wgbs-mouse-bm-hsc1",
    genome="combined",
    total_reads=["50000000"],
    data_dir=REPO / "data" / "mixtures",
    out_dir=REPO / "icrg" / "methylseq_samplesheets",
)
