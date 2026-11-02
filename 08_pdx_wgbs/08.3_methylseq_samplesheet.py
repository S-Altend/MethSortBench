import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "helper"))
from make_samplesheet_pdx import write_samplesheet, xengsort_graft_rows

script_dir   = Path(__file__).parent
out_dir      = script_dir / "methylseq_samplesheets_newindex"
pdx_data_dir = script_dir.parent / "data" / "achinger-kawecka_2024"
trimmed_dir  = pdx_data_dir / "trimmed_reads"
xengsort_dir = pdx_data_dir / "xengsort_newindex"

out_dir.mkdir(parents=True, exist_ok=True)

# --- Original trimmed reads (ICRG, bamcmp, XenofilteR alignment) ---
rows_original = []
for fq1 in sorted(trimmed_dir.glob("*_r1_val_1.fq.gz")):
    sample = fq1.name.replace("_0_r1_val_1.fq.gz", "")
    fq2 = fq1.parent / fq1.name.replace("_r1_val_1.fq.gz", "_r2_val_2.fq.gz")
    if fq2.exists():
        rows_original.append({"sample": sample, "fastq_1": str(fq1), "fastq_2": str(fq2)})

write_samplesheet(out_dir / "achinger-kawecka.csv", rows_original)

# --- XenoSort graft reads ---
rows_xengsort = xengsort_graft_rows(
    xengsort_dir, paired=True,
    sample_fn=lambda name: name.removesuffix("_0"),
)
write_samplesheet(out_dir / "achinger-kawecka_xengsort_graft.csv", rows_xengsort)
