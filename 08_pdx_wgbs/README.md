# Xengsort validation on WGBS PDX data

In this subdirectory, we applied Xengsort onto publicly available PDX models from Achinger-Kawecka et al. 2024 to proof its usage in large WGBS datasets.

## Data
| Sample | Species | SRA | GEO | Study | Sample Origin | Strain | Read length |
|------|------|------|------|------|------|------|------|
| Gar15-13-Decitabine-1 | PDX | SRX21082212 | GSM7648674 | Achinger-Kawecka 2024 | Breast Cancer PDX model | NOD-SCID-IL2γR-/- | 150 bp |
| Gar15-13-Decitabine-2 | PDX | SRX21082213 | GSM7648675 | Achinger-Kawecka 2024 | Breast Cancer PDX model | NOD-SCID-IL2γR-/- | 150 bp |
| Gar15-13-Vehicle-1 | PDX | SRX21082210 | GSM7648672 | Achinger-Kawecka 2024 | Breast Cancer PDX model | NOD-SCID-IL2γR-/- | 150 bp |
| Gar15-13-Vehicle-2 | PDX | SRX21082211 | GSM7648673 | Achinger-Kawecka 2024 | Breast Cancer PDX model | NOD-SCID-IL2γR-/- | 150 bp |
| HCI-005-Decitabine-1 | PDX | SRX21082216 | GSM7648678 | Achinger-Kawecka 2024 | Breast Cancer PDX model | NOD-SCID-IL2γR-/- | 150 bp |
| HCI-005-Decitabine-2 | PDX | SRX21082217 | GSM7648679 | Achinger-Kawecka 2024 | Breast Cancer PDX model | NOD-SCID-IL2γR-/- | 150 bp |
| HCI-005-Vehicle-1 | PDX | SRX21082214 | GSM7648676 | Achinger-Kawecka 2024 | Breast Cancer PDX model | NOD-SCID-IL2γR-/- | 150 bp |
| HCI-005-Vehicle-2 | PDX | SRX21082215 | GSM7648677 | Achinger-Kawecka 2024 | Breast Cancer PDX model | NOD-SCID-IL2γR-/- | 150 bp |

## Read sorting comparison
Again, we compare read sorting performed by Xengsort by outcomes from ICRG and bamcmp. XenofilteR was attempted but not applicable to this dataset due to R memory issues ("long vectors not supported yet"). Additionally, we assess Runtime & Memory for every single sample to evaluate the scalability of sorting tools on real biological datasets.

## Scripts

| Script | Usage | Requirements |
|--------|-------|--------------|
| [08.1_trim_galore.sh](./08.1_trim_galore.sh) | Adapter trimming and Quality Control | [trim_galore.yml](../environments/trim_galore.yml) |
| [08.2_xengsort.sh](./08.2_xengsort.sh) | Xengsort *.fastq* read sorting | [xengsort.yml](../environments/xengsort.yml) |
| [08.3_methylseq_samplesheet.py](./08.3_methylseq_samplesheet.py) | Create methylseq samplesheet for Xengsort human-sorted reads | [data_science.yml](../environments/data_science.yml) |
| [08.4_methylseq_xengsort.sh](./08.4_methylseq_xengsort.sh) | Alignment of Xengsort human-sorted reads against the human reference genome | [nextflow.yml](../environments/nextflow.yml) |
| [08.5_methylseq_icrg.sh](./08.5_methylseq_icrg.sh) | Alignment against ICRG | [nextflow.yml](../environments/nextflow.yml) |
| [08.6_methylseq_bamcmp_xenofilter.sh](./08.6_methylseq_bamcmp_xenofilter.sh) | Alignment against human and mouse reference genomes for bamcmp and XenofilteR | [nextflow.yml](../environments/nextflow.yml) |
| [08.7_xengsort_evaluate.sh](./08.7_xengsort_evaluate.sh) | Evaluate Xengsort read sorting results | [xengsort.yml](../environments/xengsort.yml) |
| [08.8_icrg_evaluate.sh](./08.8_icrg_evaluate.sh) | Evaluate ICRG read sorting results | - |
| [08.9_bamcmp_bam_sorting.sh](./08.9_bamcmp_bam_sorting.sh) | Name-sorted *.bam* files required for bamcmp input | [bamcmp.yml](../environments/bamcmp.yml) |
| [08.10_bamcmp.sh](./08.10_bamcmp.sh) | bamcmp read sorting | [bamcmp.yml](../environments/bamcmp.yml) |
| [08.11_bamcmp_evaluate.sh](./08.11_bamcmp_evaluate.sh) | Evaluate bamcmp read sorting results | - |
| [08.12_xenofilter_samplesheet.R](./08.12_xenofilter_samplesheet.R) | Create samplesheet as input for XenofilteR | [xenofilter.yml](../environments/xenofilter.yml) |
| [08.13_xenofilter_bam_sorting.sh](./08.13_xenofilter_bam_sorting.sh) | Coordinate-sorted *.bam* files required for XenofilteR input | [xenofilter.yml](../environments/xenofilter.yml) |
| [08.14_xenofilter.R](./08.14_xenofilter.R) | XenofilteR read sorting | [xenofilter.yml](../environments/xenofilter.yml) |
| [08.15_visualize.ipynb](./08.15_visualize.ipynb) | Visualize read sorting results for PDX data --> Figure 2b & Extended Data Fig. 4b | [data_science.yml](../environments/data_science.yml) |
| [08.16_runmem.ipynb](./08.16_runmem.ipynb) | Analyze runtime and memory usage for PDX data  --> Extended Data Fig. 4c | [data_science.yml](../environments/data_science.yml) |


