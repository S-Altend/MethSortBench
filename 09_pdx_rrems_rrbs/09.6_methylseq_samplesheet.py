import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "helper"))
from make_samplesheet_pdx import write_samplesheet, xengsort_graft_rows, mspi_filtered_rows

script_dir = Path(__file__).parent
out_dir    = script_dir / "methylseq_samplesheets_newindex"
data_dir   = script_dir.parent / "data" / "guillen_2022"

out_dir.mkdir(parents=True, exist_ok=True)

# --- RRBS: standard trimmed reads (used for human/mouse reference alignment) ---
write_samplesheet(
    out_dir / "guillen_rrbs.csv",
    mspi_filtered_rows(data_dir / "rrbs" / "trimmed_reads", r1_suffix="_r1_trimmed.fq.gz"),
)

# --- RRBS: standard trimmed reads for ICRG (USE_START_SITES=0) ---
write_samplesheet(
    out_dir / "guillen_rrbs_icrg.csv",
    mspi_filtered_rows(data_dir / "rrbs" / "trimmed_reads", r1_suffix="_r1_trimmed.fq.gz"),
)

# --- RRBS: MspI-prefiltered reads for ICRG (USE_START_SITES=1) ---
write_samplesheet(
    out_dir / "guillen_rrbs_icrg_mspi.csv",
    mspi_filtered_rows(data_dir / "rrbs" / "mspi_prefiltered", r1_suffix="_r1_mspi.fq.gz"),
)

# --- RREMS: standard trimmed reads (used for human/mouse reference alignment) ---
write_samplesheet(
    out_dir / "guillen_rrems.csv",
    mspi_filtered_rows(
        data_dir / "rrems" / "trimmed_reads",
        r1_suffix="_r1_val_1.fq.gz",
        r2_suffix="_r2_val_2.fq.gz",
    ),
)

# --- RREMS: standard trimmed reads for ICRG (USE_START_SITES=0) ---
write_samplesheet(
    out_dir / "guillen_rrems_icrg.csv",
    mspi_filtered_rows(
        data_dir / "rrems" / "trimmed_reads",
        r1_suffix="_r1_val_1.fq.gz",
        r2_suffix="_r2_val_2.fq.gz",
    ),
)

# --- RREMS: MspI-prefiltered reads for ICRG (USE_START_SITES=1) ---
write_samplesheet(
    out_dir / "guillen_rrems_icrg_mspi.csv",
    mspi_filtered_rows(
        data_dir / "rrems" / "mspi_prefiltered",
        r1_suffix="_r1_mspi.fq.gz",
        r2_suffix="_r2_mspi.fq.gz",
    ),
)

# --- RRBS: Xengsort graft reads ---
write_samplesheet(
    out_dir / "guillen_rrbs_xengsort_graft.csv",
    xengsort_graft_rows(data_dir / "rrbs" / "xengsort_newindex", paired=False),
)

# --- RRBS: Xengsort MspI-prefiltered graft reads (USE_START_SITES=1) ---
write_samplesheet(
    out_dir / "guillen_rrbs_xengsort_graft_mspi.csv",
    xengsort_graft_rows(data_dir / "rrbs" / "xengsort_mspi_newindex", paired=False),
)

# --- RREMS: Xengsort graft reads ---
write_samplesheet(
    out_dir / "guillen_rrems_xengsort_graft.csv",
    xengsort_graft_rows(data_dir / "rrems" / "xengsort_newindex", paired=True),
)

# --- RREMS: Xengsort MspI-prefiltered graft reads (USE_START_SITES=1) ---
if (data_dir / "rrems" / "xengsort_newindex_mspi").exists():
    write_samplesheet(
        out_dir / "guillen_rrems_xengsort_graft_mspi.csv",
        xengsort_graft_rows(data_dir / "rrems" / "xengsort_mspi_newindex", paired=True),
    )
else:
    print("Skipping guillen_rrems_xengsort_graft_mspi.csv: xengsort_mspi not found")
