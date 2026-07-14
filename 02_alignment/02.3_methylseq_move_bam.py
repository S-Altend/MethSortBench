import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "helper"))
from move_bam import move_bam

REPO = Path(__file__).parent.parent
PIPELINES = REPO / "data" / "pipelines_refseq"
OUT = REPO / "data" / "methylseq_refseq"

sample_depth_dirs = sorted(d for d in PIPELINES.glob("*/*") if d.is_dir())

job_index_str = os.environ.get("LSB_JOBINDEX")
if job_index_str is not None:
    to_process = [sample_depth_dirs[int(job_index_str) - 1]]
else:
    to_process = sample_depth_dirs

for sd_dir in to_process:
    for dedup_dir in sorted(sd_dir.rglob("bwameth/deduplicated")):
        move_bam(pipeline_dir=dedup_dir, out_dir=OUT)
