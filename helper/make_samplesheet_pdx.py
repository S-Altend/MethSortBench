"""
Shared helpers for building nf-core/methylseq samplesheets from PDX datasets.
Used by 08_pdx, 09_pdx_guillen_2022, and 10_pdox_zhao.
"""

import csv
from pathlib import Path


def write_samplesheet(out_path, rows):
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["sample", "fastq_1", "fastq_2"])
        writer.writeheader()
        writer.writerows(rows)
    print(f"Written {len(rows)} samples to {out_path}")
    for r in rows:
        print(f"  {r['sample']}")


def xengsort_graft_rows(xengsort_dir, paired, sample_fn=None):
    """
    Collect rows from xengsort output dirs.

    Parameters
    ----------
    xengsort_dir : Path
    paired : bool
        True  → graft.1.fq.gz / graft.2.fq.gz
        False → graft.fq.gz
    sample_fn : callable, optional
        Maps dir name -> sample name. Defaults to identity.
    """
    xengsort_dir = Path(xengsort_dir)
    sample_fn = sample_fn or (lambda n: n)
    rows = []
    for d in sorted(xengsort_dir.iterdir()):
        if not d.is_dir():
            continue
        sample = sample_fn(d.name)
        if paired:
            fq1 = d / f"{d.name}-graft.1.fq.gz"
            fq2 = d / f"{d.name}-graft.2.fq.gz"
            if fq1.exists() and fq2.exists():
                rows.append({"sample": sample, "fastq_1": str(fq1), "fastq_2": str(fq2)})
            else:
                print(f"WARNING: missing graft pair for {d.name}, skipping")
        else:
            fq1 = d / f"{d.name}-graft.fq.gz"
            if fq1.exists():
                rows.append({"sample": sample, "fastq_1": str(fq1), "fastq_2": ""})
            else:
                print(f"WARNING: no graft file for {d.name}, skipping")
    return rows


def mspi_filtered_rows(mspi_dir, r1_suffix, r2_suffix=None, sample_fn=None):
    """
    Collect rows from an mspi_prefiltered directory.

    Parameters
    ----------
    mspi_dir : Path
    r1_suffix : str
        Suffix to match R1 files, e.g. "_r1_mspi.fq.gz".
    r2_suffix : str, optional
        Suffix for R2 files. None for single-end.
    sample_fn : callable, optional
        Maps stem (filename minus r1_suffix) -> sample name. Defaults to identity.
    """
    mspi_dir = Path(mspi_dir)
    sample_fn = sample_fn or (lambda n: n)
    rows = []
    for fq1 in sorted(mspi_dir.glob(f"*{r1_suffix}")):
        stem = fq1.name[: -len(r1_suffix)]
        sample = sample_fn(stem)
        if r2_suffix:
            fq2 = mspi_dir / f"{stem}{r2_suffix}"
            if fq2.exists():
                rows.append({"sample": sample, "fastq_1": str(fq1), "fastq_2": str(fq2)})
            else:
                print(f"WARNING: missing R2 for {stem}, skipping")
        else:
            rows.append({"sample": sample, "fastq_1": str(fq1), "fastq_2": ""})
    return rows
