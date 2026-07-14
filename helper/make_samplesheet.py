"""
Generate nf-core methylseq samplesheets from benchmark data directories.
"""

import argparse
import re
from pathlib import Path

import pandas as pd


def _list_subdirs(p):
    return sorted(x for x in p.iterdir() if x.is_dir())


def _filter(names, allowed):
    """Return names unchanged if allowed is None, otherwise filter to the allowed set."""
    if allowed is None:
        return names
    allowed_set = set(allowed)
    return [n for n in names if n in allowed_set]


_rep_patterns = [
    re.compile(r".*?_rep(\d+).*", re.IGNORECASE),  # *_repN_*
    re.compile(r"mixed_(\d+)"),                     # mixed_N_* or mixed_N-graft.*
]


def _get_replicate(path):
    """Return replicate index as int, or None if the filename doesn't match."""
    for pat in _rep_patterns:
        m = pat.match(path.name)
        if m:
            return int(m.group(1))
    return None


def _pair_reads(folder, mode):
    """Return sorted (r1, r2) Path pairs for the given naming convention.

    Parameters
    ----------
    folder : Path
    mode : {"mixed", "graft"}
    """
    if mode == "graft":
        r1_glob, r1_suf, r2_suf = "mixed_*-graft.1.fq.gz", ".1.fq.gz", ".2.fq.gz"
    else:
        r1_glob, r1_suf, r2_suf = "*mixed*_r1.fastq.gz", "_r1.fastq.gz", "_r2.fastq.gz"

    r1_files = sorted(folder.glob(r1_glob))
    if not r1_files:
        return []

    pairs, missing = [], []
    for r1 in r1_files:
        r2 = folder / r1.name.replace(r1_suf, r2_suf)
        if r2.exists():
            pairs.append((r1, r2))
        else:
            missing.append(r2)

    if missing:
        raise FileNotFoundError(
            f"Missing R2 files in {folder}:\n" + "\n".join(map(str, missing))
        )
    return pairs


def make_samplesheet(
    data_dir,
    out_dir,
    human,
    mouse,
    genome,
    total_reads,
    mixtures=None,
    mode="mixed",
    replicates=None,
    out_prefix="",
):
    """Build and write one samplesheet CSV per total-read count.

    Parameters
    ----------
    data_dir : Path
        Root directory containing ``<human>_<mouse>/`` subdirectories.
    out_dir : Path
        Directory where CSV files are written (created if absent).
    human : str
        Human sample name (e.g. ``"wgbs-human-pancreas-organoid2"``).
    mouse : str
        Mouse sample name (e.g. ``"wgbs-mouse-pancreas-organoid2"``).
    genome : str
        Genome label written into the samplesheet (e.g. ``"GRCh38"``).
    total_reads : list of str
        Total-read count folder names to include (e.g. ``["10000000"]``).
    mixtures : list of str, optional
        Mixture folder names to include (e.g. ``["10p", "20p"]``).
        ``None`` means include all found.
    mode : {"mixed", "graft"}
        File naming convention.
        ``"mixed"`` expects ``*mixed*_r1.fastq.gz`` / ``*_r2.fastq.gz``.
        ``"graft"`` expects ``mixed_*-graft.1.fq.gz`` / ``*.2.fq.gz``.
    replicates : list of int, optional
        Replicate indices to include. ``None`` means include all found.
    out_prefix : str, optional
        Prefix prepended to the output filename (e.g. ``"xengsort_graft_"``).
    """
    data_dir = Path(data_dir)
    out_dir = Path(out_dir)

    sample_comb = f"{human}_{mouse}"
    sample_comb_path = data_dir / sample_comb

    total_read_names = _filter(
        [d.name for d in _list_subdirs(sample_comb_path)], total_reads
    )
    if not total_read_names:
        raise FileNotFoundError(f"No total-reads folders found under {sample_comb_path}")

    out_dir.mkdir(parents=True, exist_ok=True)
    columns = ["sample", "fastq_1", "fastq_2", "genome"]

    for total_read in total_read_names:
        total_read_path = sample_comb_path / total_read
        mixture_names = _filter(
            [d.name for d in _list_subdirs(total_read_path)], mixtures
        )
        if not mixture_names:
            print(f"[WARN] No mixture folders under {total_read_path}")
            continue

        rows = []
        for mixture in mixture_names:
            mix_path = total_read_path / mixture
            pairs = _pair_reads(mix_path, mode)
            if not pairs:
                print(f"[WARN] No reads found in {mix_path}")
                continue

            for r1, r2 in pairs:
                rep = _get_replicate(r1)
                if replicates is not None and rep not in replicates:
                    continue
                rep_label = f"rep{rep}" if rep is not None else r1.stem
                sample_name = f"{sample_comb}_{total_read}_{mixture}_{rep_label}_{genome}"
                rows.append([sample_name, str(r1), str(r2), ""])

        if not rows:
            print(f"[WARN] No rows for {sample_comb}/{total_read}")
            continue

        out_name = f"{out_prefix}{sample_comb}_{total_read}_{genome}.csv"
        out_path = out_dir / out_name
        pd.DataFrame(rows, columns=columns).to_csv(out_path, index=False)
        print(f"[OK] Wrote {len(rows)} rows -> {out_path}")


def _parse_args():
    p = argparse.ArgumentParser(
        description="Generate nf-core methylseq samplesheets from benchmark data.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("--data-dir", type=Path, required=True,
                   help="Root dir: <human>_<mouse>/<total_reads>/<mixture>/")
    p.add_argument("--out-dir", type=Path, required=True,
                   help="Output directory for samplesheet CSVs")
    p.add_argument("--human", required=True,
                   help="Human sample name, e.g. wgbs-human-pancreas-organoid2")
    p.add_argument("--mouse", required=True,
                   help="Mouse sample name, e.g. wgbs-mouse-pancreas-organoid2")
    p.add_argument("--genome", required=True,
                   help="Genome label in the CSV, e.g. GRCh38")
    p.add_argument("--total-reads", nargs="+", required=True,
                   help="Total-read count folder names, e.g. 10000000 50000000")
    p.add_argument("--mixtures", nargs="+", default=None,
                   help="Mixture folders to include, e.g. 10p 20p 90p. Default: all.")
    p.add_argument("--mode", choices=["mixed", "graft"], default="mixed",
                   help="'mixed' (*_r1.fastq.gz) or 'graft' (*-graft.1.fq.gz)")
    p.add_argument("--replicates", nargs="+", type=int, default=None,
                   help="Replicate indices to keep, e.g. 0 1 2. Default: all.")
    p.add_argument("--out-prefix", default="",
                   help="Prefix prepended to the output CSV filename.")
    return p.parse_args()


if __name__ == "__main__":
    args = _parse_args()
    make_samplesheet(
        data_dir=args.data_dir,
        out_dir=args.out_dir,
        human=args.human,
        mouse=args.mouse,
        genome=args.genome,
        total_reads=args.total_reads,
        mixtures=args.mixtures,
        mode=args.mode,
        replicates=args.replicates,
        out_prefix=args.out_prefix,
    )
