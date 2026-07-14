import os
import re
from pathlib import Path
import pandas as pd


# ---------------------------------------------------------------------------
# Trace file helpers
# ---------------------------------------------------------------------------

def load_trace_file(data_dir):
    trace_dir = data_dir / "pipeline_info"
    files = list(trace_dir.glob("execution_trace_*"))
    if len(files) > 1:
        raise ValueError("Multiple execution traces found. Please keep only one.")
    elif len(files) == 0:
        raise FileNotFoundError(f"No execution trace found in {trace_dir}")
    return pd.read_table(files[0], index_col=0)


def to_seconds(s):
    return (
        pd.to_timedelta(
            s.replace("h", "h ")
             .replace("m", "m ")
             .replace("s", "s")
        ).total_seconds()
    )


def to_megabytes(s):
    return pd.to_numeric(
        s.str.replace(" GB", "e3")    # 1 GB = 1000 MB
         .str.replace(" MB", "")
         .str.replace(" KB", "e-3"),  # 1 KB = 0.001 MB
        errors="coerce"
    )


def transform_runmem_results(df):
    df = df.copy()
    df["realtime_s"] = df["realtime"].apply(to_seconds)
    df.drop(columns=["realtime"], inplace=True)
    for col in ["peak_rss", "peak_vmem", "rchar", "wchar"]:
        df[col + "_mb"] = to_megabytes(df[col])
        df.drop(columns=[col], inplace=True)
    return df[["method", "sample", "realtime_s", "peak_rss_mb"]]

def transform_runmem(runmem):
    runmem_new = runmem.copy()
    runmem_new["realtime_h"] = runmem_new["realtime_s"] / 3600
    runmem_new["peak_rss_gb"] = runmem_new["peak_rss_mb"] / 1000
    return(runmem_new)
# ---------------------------------------------------------------------------
# Per-pipeline aggregation
# ---------------------------------------------------------------------------

def alignment_runmem(base_dir, pipeline, out_dir):
    data_dir = base_dir / pipeline
    out_dir = out_dir / pipeline
    out_dir.mkdir(exist_ok=True, parents=True)
    df = load_trace_file(data_dir)
    df.to_csv(out_dir / "trace.csv")

    df["method"] = (
        df["name"].str.split(" ").apply(lambda x: x[0])
                  .str.split(":").apply(lambda x: x[-1])
    )
    df["sample"] = df["name"].str.extract(r"\(([^)]+)\)")

    keep_methods = ["BWAMETH_ALIGN", "SAMTOOLS_SORT", "SAMTOOLS_INDEX_ALIGNMENTS"]
    df_filt = df[df["method"].isin(keep_methods)]
    df_filt.to_csv(out_dir / "trace_filt.csv")

    df_nums = df_filt[["method", "sample", "realtime", "%cpu", "peak_rss", "peak_vmem", "rchar", "wchar"]]
    df_nums.to_csv(out_dir / "nums.csv")

    df_transf = transform_runmem_results(df_nums)

    agg = (
        df_transf
        .groupby("sample").agg(
            realtime_s=("realtime_s", "sum"),
            peak_rss_mb=("peak_rss_mb", "max"),
        )
    )
    agg.to_csv(out_dir / "alignment.csv")

    return agg


def process_all_pipelines(pipeline_dir, out_dir):
    """Run alignment_runmem for every pipeline subdirectory in pipeline_dir.

    Returns
    -------
    dict[str, pd.DataFrame]
        Mapping pipeline name -> aggregated (sample × realtime_s/peak_rss_mb) DataFrame.
    """
    pipelines = [p for p in os.listdir(pipeline_dir) if (Path(pipeline_dir) / p).is_dir()]
    return {p: alignment_runmem(pipeline_dir, p, out_dir) for p in pipelines}


# ---------------------------------------------------------------------------
# Combining / reshaping
# ---------------------------------------------------------------------------

def combine_pipeline_dfs(dfs, strip_suffix=True):
    """Concatenate per-pipeline DataFrames and add a 'pipeline' column.

    Parameters
    ----------
    dfs : dict[str, pd.DataFrame]
        Output of process_all_pipelines.
    strip_suffix : bool, optional
        If True (default), strips the last '_'-separated token from sample names.
        This is intended for benchmark datasets where sample names carry a
        read-count suffix (e.g. 'sample_100M' -> 'sample').
        Set to False when sample names should be used as-is (e.g. PDX datasets).

    Returns
    -------
    pd.DataFrame
        Columns: pipeline, sample, realtime_s, peak_rss_mb
    """
    df = pd.concat(dfs).reset_index()
    df = df.rename(columns={"level_0": "pipeline"})
    df["replicate"] = df["sample"].str.extract(r"_rep(\d+)(?:_|$)").astype("Int64")
    if strip_suffix:
        df["sample"] = df["sample"].str.split("_").apply(lambda x: "_".join(x[:-1]))
    return df


# ---------------------------------------------------------------------------
# Method-specific extraction (default benchmark naming convention)
# ---------------------------------------------------------------------------

def extract_bamcmp_xenofilter(df):
    """Derive bamcmp and XenofilteR rows from the 'all_*' pipelines.

    Both methods share the same alignment runtime (they only differ in the
    downstream read-sorting step), so the same aggregated numbers are
    duplicated under each method label.

    Parameters
    ----------
    df : pd.DataFrame
        Output of combine_pipeline_dfs.

    Returns
    -------
    tuple[pd.DataFrame, pd.DataFrame]
        (df_bamcmp, df_xenofilter)
    """
    df_mh = df[df["pipeline"].str.contains("all_")].copy()
    df_mh["pipeline"] = df_mh["pipeline"].str.split("_").str[1]

    agg = (
        df_mh.groupby("sample", as_index=False)
        .agg(
            sample=("pipeline", "first"),
            replicate=("replicate", "first"),
            realtime_s=("realtime_s", "sum"),
            peak_rss_mb=("peak_rss_mb", "max"),
        )
    )

    df_bm = agg.copy()
    df_bm["method"] = "bamcmp"

    df_xfr = agg.copy()
    df_xfr["method"] = "XenofilteR"

    return df_bm, df_xfr


def extract_xengsort(df):
    """Extract Xengsort rows from the 'xengsort_*' pipelines.

    Parameters
    ----------
    df : pd.DataFrame
        Output of combine_pipeline_dfs.

    Returns
    -------
    pd.DataFrame
        Columns: sample, realtime_s, peak_rss_mb, method
    """
    df_xg = df[df["pipeline"].str.contains("xengsort")].copy()
    df_xg["sample"] = df_xg["pipeline"].str.split("_").str[1]
    df_xg = df_xg.drop(columns=["pipeline"]).reset_index(drop=True)
    df_xg["method"] = "Xengsort"
    return df_xg


def extract_icrg(df):
    """Extract ICRG rows from the 'combined_*' pipelines.

    Parameters
    ----------
    df : pd.DataFrame
        Output of combine_pipeline_dfs.

    Returns
    -------
    pd.DataFrame
        Columns: sample, realtime_s, peak_rss_mb, method
    """
    df_cb = df[df["pipeline"].str.contains("combined")].copy()
    df_cb["sample"] = df_cb["pipeline"].str.split("_").str[1]
    df_cb = df_cb.drop(columns=["pipeline"]).reset_index(drop=True)
    df_cb["method"] = "ICRG"
    return df_cb


# ---------------------------------------------------------------------------
# LSF log parsing
# ---------------------------------------------------------------------------

def parse_lsf_logs(log_dir, method="Xengsort", pattern="*.out"):
    """Parse LSF .out log files and extract runtime/memory for successful jobs.

    Each log file may contain multiple job records (e.g. failed retries followed
    by a successful run). Only records marked 'Successfully completed.' are used.
    Sample names are stripped of a trailing numeric suffix (e.g. '_0').

    Parameters
    ----------
    log_dir : str or Path
        Directory containing LSF .out log files.
    method : str, optional
        Method label to assign to all rows. Defaults to "Xengsort".
    pattern : str, optional
        Glob pattern to filter log files. Defaults to "*.out".

    Returns
    -------
    pd.DataFrame
        Columns: sample, realtime_s, peak_rss_mb, method
    """
    log_dir = Path(log_dir)
    records = []

    for log_file in sorted(log_dir.glob(pattern)):
        text = log_file.read_text()
        jobs = re.split(r"(?=Sender: LSF System)", text)
        for job in jobs:
            if "Successfully completed." not in job:
                continue
            m_time   = re.search(r"Run time\s*:\s*([\d.]+)\s*sec\.", job)
            m_mem    = re.search(r"Max Memory\s*:\s*([\d.]+)\s*MB", job)
            m_sample = re.search(r"^(?:Processing )?[Ss]ample:\s*(.+)$", job, re.MULTILINE)
            # Fallback: extract sample/replicate from XenofilteR BAM path
            if m_sample is None:
                m_sample = re.search(
                    r"graft:.*?/(wgbs-human-[^/]+_wgbs-mouse-[^/]+)/\d+/\w+/mixed_(\d+)_",
                    job
                )
                if m_sample:
                    sample = m_sample.group(1)
                    rep    = int(m_sample.group(2))
                else:
                    continue
            else:
                raw    = m_sample.group(1).strip()
                m_rep  = re.search(r",?\s*replicate:\s*(\d+)$", raw)
                rep    = int(m_rep.group(1)) if m_rep else None
                sample = re.sub(r",?\s*replicate:\s*\d+$", "", raw)
                sample = re.sub(r"_\d+$", "", sample)
            if not (m_time and m_mem):
                continue
            records.append({
                "sample":      sample,
                "replicate":   rep,
                "realtime_s":  float(m_time.group(1)),
                "peak_rss_mb": float(m_mem.group(1)),
                "method":      method,
            })

    df = pd.DataFrame(records)
    if not df.empty:
        # Keep last successful run per sample (reruns append to the same log file)
        df = df.groupby(["sample", "replicate"], dropna=False).last().reset_index()
    return df


# ---------------------------------------------------------------------------
# Top-level wrapper
# ---------------------------------------------------------------------------

def process_nfcore_traces(base_dir, out_dir=None, pipeline_method_map=None):
    """Process all nf-core trace files and produce alignment_tools.csv.

    1. Load and aggregate each pipeline's execution trace.
    2. Combine into a single DataFrame.
    3. Assign methods either via pipeline_method_map or the default benchmark logic.
    4. Save intermediate CSVs under out_dir.
    5. Save the final alignment_tools.csv to both out_dir and base_dir.

    Parameters
    ----------
    base_dir : str or Path
        Directory that contains 'pipelines/' (input) and will receive
        'alignment_tools.csv' (output).
    out_dir : str or Path, optional
        Directory for per-pipeline and per-method CSV outputs.
        Defaults to base_dir / 'nfcore_traces'.
    pipeline_method_map : dict, optional
        Maps method names to one or more pipeline names whose runtimes
        should be summed (realtime_s) / max-ed (peak_rss_mb) per sample.
        When provided, replaces the default all_/xengsort_/combined_ logic.

        Example for a PDX dataset::

            pipeline_method_map = {
                "ICRG":       ["methylseq_bwameth_icrg"],
                "bamcmp":     ["methylseq_bwameth_GRCh38", "methylseq_bwameth_GRCm38"],
                "XenofilteR": ["methylseq_bwameth_GRCh38", "methylseq_bwameth_GRCm38"],
            }

    Returns
    -------
    pd.DataFrame
        Final table with columns: sample, realtime_s, peak_rss_mb, method, stage.
    """
    base_dir = Path(base_dir)
    out_dir = Path(out_dir) if out_dir is not None else base_dir / "nfcore_traces"
    pipeline_dir = base_dir / "pipelines"

    # 1. Per-pipeline aggregation
    if pipeline_method_map is not None:
        needed = set(p for ps in pipeline_method_map.values() for p in ps)
        missing = [p for p in needed if not (pipeline_dir / p).is_dir()]
        if missing:
            raise FileNotFoundError(f"Pipeline directories not found: {missing}")
        dfs = {p: alignment_runmem(pipeline_dir, p, out_dir) for p in needed}
    else:
        dfs = process_all_pipelines(pipeline_dir, out_dir)

    # 2. Combine
    strip = pipeline_method_map is None  # only strip suffix for default benchmark datasets
    df1 = combine_pipeline_dfs(dfs, strip_suffix=strip)

    # 3. Build per-method DataFrames
    if pipeline_method_map is not None:
        method_dfs = []
        for method, pipelines in pipeline_method_map.items():
            subset = df1[df1["pipeline"].isin(pipelines)].copy()
            # nf-core appends a _0 (or _N) read-group suffix to sample names in
            # single-sample runs; strip it so human and mouse rows merge correctly.
            subset["sample"] = subset["sample"].str.replace(r"_\d+$", "", regex=True)
            agg = (
                subset.groupby("sample", as_index=False)
                .agg(
                    realtime_s=("realtime_s", "sum"),
                    peak_rss_mb=("peak_rss_mb", "max"),
                )
            )
            agg["method"] = method
            agg.to_csv(out_dir / f"{method.lower()}.csv", index=False)
            method_dfs.append(agg)
        df_final = pd.concat(method_dfs).reset_index(drop=True)
    else:
        # Default: benchmark dataset naming (all_*, xengsort_*, combined_*)
        df_bm, df_xfr = extract_bamcmp_xenofilter(df1)
        df_xg = extract_xengsort(df1)
        df_cb = extract_icrg(df1)
        df_bm.to_csv(out_dir / "bamcmp.csv", index=False)
        df_xfr.to_csv(out_dir / "xenofilter.csv", index=False)
        df_xg.to_csv(out_dir / "xengsort.csv", index=False)
        df_cb.to_csv(out_dir / "icrg.csv", index=False)
        df_final = pd.concat([df_bm, df_cb, df_xg, df_xfr]).reset_index(drop=True)

    # 4. Save final result
    df_final["stage"] = "alignment"
    df_final.to_csv(out_dir / "alignment_tools.csv", index=False)
    df_final.to_csv(base_dir / "alignment_tools.csv", index=False)

    return df_final

def split_runmem(df):
    use0 = df[df["sample"].str.contains("use-start-sites: 0")].copy()
    use1 = df[df["sample"].str.contains("use-start-sites: 1")].copy()

    for d in [use0, use1]:
        d["sample"] = d["sample"].str.replace(r" \|.*", "", regex=True)

    return use0.reset_index(drop=True), use1.reset_index(drop=True)


def split_runmem_assay(df):
    """Split a parse_lsf_logs DataFrame by assay (rrbs / rrems) and use-start-sites.

    Expects sample strings in the format produced by 09.17_bamcmp.sh:
        '<sample> | assay: <assay> | use-start-sites: <0|1>'

    Returns
    -------
    dict with keys 'rrbs', 'rrems', 'rrbs_mspi', 'rrems_mspi'
    """
    result = {}
    for assay in ("rrbs", "rrems"):
        for use_ss, suffix in (("0", ""), ("1", "_mspi")):
            mask = (
                df["sample"].str.contains(f"assay: {assay}") &
                df["sample"].str.contains(f"use-start-sites: {use_ss}")
            )
            subset = df[mask].copy()
            subset["sample"] = subset["sample"].str.replace(r" \|.*", "", regex=True)
            result[f"{assay}{suffix}"] = subset.reset_index(drop=True)
    return result

