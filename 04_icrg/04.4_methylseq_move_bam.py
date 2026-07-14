import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "helper"))
from move_bam import move_bam

REPO = Path(__file__).parent.parent

move_bam(
    pipeline_dir=REPO / "data" / "pipeline_organoid2_50M_combined" / "bwameth" / "deduplicated",
    out_dir=REPO / "data" / "icrg",
)
