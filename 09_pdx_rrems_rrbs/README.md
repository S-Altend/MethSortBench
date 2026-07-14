# Xengsort validation on Patient-Derived Xenograft (PDX) data from Guillen et al. 2022

In this subdirectory, we applied Xengsort onto publicly available PDX, PDXO (Patient-derived Xenograft Organoids) and human patient samples from **Guillen et al. 2022** to proof its usage in biological datasets across 2 different Reduced-Representation methylation sequencing technologies: Bisulfite Sequencing (**RRBS**) and Enzymatic Sequencing (**RREMS**). These protocols use restriction enzymes such as **MspI** (cut site: C/CGG) which enrich for CpG-rich regions in the methylome before subsequent sequencing.

## Data
| Attribute | Value |
|-----------|-------|
| Study | Guillen 2022 |
| SRA Study accession | SRP343608 |
| BioProject | PRJNA775956 |
| Sample origin | Breast cancer PDX models (HCI series), matched trios of Patient tumor / PDX / PDxO (patient-derived xenograft organoid) |
| Library preps | RRBS (single-end, 50 bp) and RREM-seq (paired-end, 50 bp) |
| RRBS samples | 11 |
| RREM-seq samples | 20 |


## Read sorting comparison
As with the [other PDX cohort](../08_pdx_wgbs/), we compare read sorting performed by Xengsort against outcomes from ICRG, bamcmp, and XenofilteR across both RRBS and RREMS samples, with and without an in-silico MspI-eligibility prefilter applied to reads before sorting. Runtime & Memory are assessed per sample and per protocol to evaluate scalability. For XenofilteR, we used the default MM-threshold of 4 to account for the smaller read length. The other algorithms were applied as in the *in silico* benchmark before.

## Scripts

| Script | Usage | Requirement |
|--------|-------|-------------|
| [09.1_trimgalore_rrems.sh](./09.1_trimgalore_rrems.sh) | Adapter trimming and Quality Control for RREMS reads | [trim_galore.yml](../environments/trim_galore.yml) |
| [09.2_trimgalore_rrbs.sh](./09.2_trimgalore_rrbs.sh) | Adapter trimming and Quality Control for RRBS reads | [trim_galore.yml](../environments/trim_galore.yml) |
| [09.3_xengsort_rrbs.sh](./09.3_xengsort_rrbs.sh) | Xengsort *.fastq* read sorting for RRBS reads | [xengsort.yml](../environments/xengsort.yml) |
| [09.4_xengsort_rrems.sh](./09.4_xengsort_rrems.sh) | Xengsort *.fastq* read sorting for RREMS reads | [xengsort.yml](../environments/xengsort.yml) |
| [09.5_xengsort_evaluate.sh](./09.5_xengsort_evaluate.sh) | Evaluate Xengsort read sorting results (RRBS + RREMS) | [xengsort.yml](../environments/xengsort.yml) |
| [09.6_methylseq_samplesheet.py](./09.6_methylseq_samplesheet.py) | Create methylseq samplesheets for RRBS/RREMS, incl. Xengsort-graft and MspI-prefiltered variants | [data_science.yml](../environments/data_science.yml) |
| [09.7_methylseq_xengsort_rrbs.sh](./09.7_methylseq_xengsort_rrbs.sh) | Alignment of Xengsort human-sorted RRBS reads against the human reference genome | [nextflow.yml](../environments/nextflow.yml) |
| [09.7_methylseq_xengsort_rrems.sh](./09.7_methylseq_xengsort_rrems.sh) | Alignment of Xengsort human-sorted RREMS reads against the human reference genome | [nextflow.yml](../environments/nextflow.yml) |
| [09.8_mspi_prefilter_rrems.sh](./09.8_mspi_prefilter_rrems.sh) | Prefilter RREMS trimmed reads to MspI-eligible read pairs before Xengsort | - |
| [09.9_mspi_prefilter_rrbs.sh](./09.9_mspi_prefilter_rrbs.sh) | Prefilter RRBS trimmed reads to MspI-eligible reads before Xengsort | - |
| [09.11_methylseq_icrg_rrems.sh](./09.11_methylseq_icrg_rrems.sh) | Alignment of RREMS human-mouse mixtures against ICRG | [nextflow.yml](../environments/nextflow.yml) |
| [09.12_methylseq_icrg_rrbs.sh](./09.12_methylseq_icrg_rrbs.sh) | Alignment of RRBS human-mouse mixtures against ICRG | [nextflow.yml](../environments/nextflow.yml) |
| [09.13_icrg_evaluate.sh](./09.13_icrg_evaluate.sh) | Evaluate ICRG read sorting results (RRBS + RREMS, incl. MspI variants) | - |
| [09.13_methylseq_human_rrems.sh](./09.13_methylseq_human_rrems.sh) | Alignment of RREMS human-mouse mixtures against the human or mouse reference genome; required for bamcmp and XenofilteR read sorting | [nextflow.yml](../environments/nextflow.yml) |
| [09.15_methylseq_human_rrbs.sh](./09.15_methylseq_human_rrbs.sh) | Alignment of RRBS human-mouse mixtures against the human or mouse reference genome; required for bamcmp and XenofilteR read sorting | [nextflow.yml](../environments/nextflow.yml) |
| [09.16_bamcmp_bam_sorting.sh](./09.16_bamcmp_bam_sorting.sh) | Name-sorted *.bam* files required for bamcmp input | [bamcmp.yml](../environments/bamcmp.yml) |
| [09.17_bamcmp.sh](./09.17_bamcmp.sh) | bamcmp read sorting | [bamcmp.yml](../environments/bamcmp.yml) |
| [09.18_bamcmp_evaluate.sh](./09.18_bamcmp_evaluate.sh) | Evaluate bamcmp read sorting results | - |
| [09.19_xenofilter_samplesheet.R](./09.19_xenofilter_samplesheet.R) | Create samplesheet as input for XenofilteR | [xenofilter.yml](../environments/xenofilter.yml) |
| [09.20_xenofilter_bam_sorting.sh](./09.20_xenofilter_bam_sorting.sh) | Coordinate-sorted *.bam* files required for XenofilteR input | [xenofilter.yml](../environments/xenofilter.yml) |
| [09.21_xenofilter.R](./09.21_xenofilter.R) | XenofilteR read sorting | [xenofilter.yml](../environments/xenofilter.yml) |
| [09.22_xenofilter_evaluate.sh](./09.22_xenofilter_evaluate.sh) | Evaluate XenofilteR read sorting results | - |
| [09.23_visualize.ipynb](./09.23_visualize.ipynb) | Visualize read sorting and runtime memory results for the Guillen PDX cohort | [data_science.yml](../environments/data_science.yml) |

