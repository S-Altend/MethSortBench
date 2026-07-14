"""
Reorganize deduplicated BAM files from an nf-core methylseq run into the
benchmark directory tree: <out_dir>/<human>_<mouse>/<total_reads>/<mixture>/.
"""

import argparse
import shutil
from pathlib import Path


def move_bam(pipeline_dir, out_dir):
    """Copy BAM files from an nf-core methylseq output into the benchmark tree.

    Parameters
    ----------
    pipeline_dir : Path
        Directory containing ``*.markdup.sorted.bam`` files.
    out_dir : Path
        Root of the benchmark output tree.
        Files are placed at ``<out_dir>/<human>_<mouse>/<total_reads>/<mixture>/``.
    """
    pipeline_dir = Path(pipeline_dir)
    out_dir = Path(out_dir)
    out_dir.mkdir(exist_ok=True)

    bam_files = sorted(pipeline_dir.glob("*.markdup.sorted.bam"))
    print(f"Found {len(bam_files)} BAM files in {pipeline_dir}")

    for bam_file in bam_files:
        base = bam_file.name.replace(".markdup.sorted.bam", "")
        human, mouse, total_reads, mixture, replicate, genome = base.split("_")

        bam_dir = out_dir / f"{human}_{mouse}" / total_reads / mixture
        bam_dir.mkdir(parents=True, exist_ok=True)

        dst = bam_dir / f"mixed_{replicate}_{genome}.sorted.bam"
        if dst.exists():
            print(f"Skipped (destination exists):\t{bam_file}")
            continue
        shutil.move(str(bam_file), dst)
        print(f"Moved:\t{bam_file}\n-->\t{dst}\n")


if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="Reorganize methylseq BAMs into the benchmark directory tree."
    )
    p.add_argument("--pipeline-dir", type=Path, required=True,
                   help="Directory containing *.markdup.sorted.bam files")
    p.add_argument("--out-dir", type=Path, required=True,
                   help="Root output directory for the benchmark tree")
    args = p.parse_args()
    move_bam(args.pipeline_dir, args.out_dir)
