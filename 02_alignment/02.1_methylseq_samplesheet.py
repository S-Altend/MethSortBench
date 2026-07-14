import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "helper"))
from make_samplesheet import make_samplesheet

REPO = Path(__file__).parent.parent

make_samplesheet(
    human="wgbs-human-pancreas-organoid2",
    mouse="wgbs-mouse-pancreas-organoid2",
    genome="GRCh38",
    total_reads=["10000000"],
    data_dir=REPO / "data" / "mixtures",
    out_dir=Path(__file__).parent / "methylseq_samplesheets",
)
