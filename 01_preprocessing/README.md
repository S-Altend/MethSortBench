# Preprocessing of raw WGBS files
In this subdirectory, downloaded raw WGBS files are preprocessed for further alignment and read sorting tasks. 

## Read trimming (Adapter removal + Quality Control)
First, *.fastq* files were conservatively trimmed and quality-filtered via TrimGalore! (v0.6.10). Reads were trimmed with a Phred quality threshold of 20, and fixed clipping was applied to remove 10 bp from both the 5′ and 3′ ends of each mate (R1 and R2). FastQC reports were generated for quality control.

## In silico read mixing
In silico human–mouse mixtures were generated from adapter-trimmed paired-end FASTQ files using seqkit (v2.13.0). For each dataset pair, reads were randomly subsampled at predefined mixture ratios ranging from 10% to 90% human content (increments of 10%).

Two total sequencing depths were evaluated: 50 million and 10 million paired-end reads per mixture (corresponding to 100 million and 20 million single reads, respectively). For each mixture ratio and sequencing depth, six independent replicates were generated using distinct random seeds (0–5)

For each replicate, human and mouse reads were subsampled independently using identical random seeds for read 1 and read 2 to preserve pairing relationships. Subsampled reads were concatenated to produce mixed FASTQ files. To retain ground-truth species origin after merging, read identifiers were prefixed with “human_” or “mouse_” prior to concatenation.

### Experimental design 

- Mixtures: Mix 1, Mix 2, Mix 3, Mix 4
  - Depth: 10M PE reads
    - Human ratio: 0.1–0.9 (step 0.1)
      - Replicates: R1–R6
  - Depth: 50M PE reads
    - Human ratio: 0.1–0.9 (step 0.1)
      - Replicates: R1–R6
Totals:
- Conditions (M × depth × ratio) = 4 × 2 × 9 = 72
- With replicates = 72 × 6 = 432

### Sample combinations 

| Mixture   | Species | SRA         | GEO        | Study                           | Sample origin                                        | Strain  | Read length |
| --------- | ------- | ----------- | ---------- | ------------------------------- | ---------------------------------------------------- | ------- | ----------- |
| Mixture 1 | Human   | SRR1035790  | GSM1279514 | Carmona et al., Cancer Res 2014 | Breast cancer cell line                              | NA      | 100 bp      |
| Mixture 1 | Mouse   | SRR892982   | GSM1160012 | Sun et al., Cell Stem Cell 2014 | Bone marrow derived primary hematopoietic stem cells | C57BL/6 | 100 bp      |
| Mixture 2 | Human   | SRR26107707 | GSM7790009 | Wang et al., iScience 2024      | Normal pancreatic ductal patient-derived organoid    | NA      | 150 bp      |
| Mixture 2 | Mouse   | SRR26107672 | GSM7790044 | Wang et al., iScience 2024      | Normal pancreatic ductal mouse organoid              | C57BL/6 | 150 bp      |
| Mixture 3 | Human   | SRR26107706 | GSM7790010 | Wang et al., iScience 2024      | Normal pancreatic ductal patient-derived organoid    | NA      | 150 bp      |
| Mixture 3 | Mouse   | SRR26107671 | GSM7790045 | Wang et al., iScience 2024      | Normal pancreatic ductal mouse organoid              | C57BL/6 | 150 bp      |
| Mixture 4 | Human   | SRR26107705 | GSM7790011 | Wang et al., iScience 2024      | Normal pancreatic ductal patient-derived organoid    | NA      | 150 bp      |
| Mixture 4 | Mouse   | SRR26107670 | GSM7790046 | Wang et al., iScience 2024      | PanIN mouse organoid                                 | C57BL/6 | 150 bp      |


## Scripts
| Script                                                    | Usage                                      | Requirements                                       |
| --------------------------------------------------------- | ------------------------------------------ | -------------------------------------------------- |
| [01.1_trim_galore.sh](./01.1_trim_galore.sh)              | Adapter trimming and Quality Control       | [trim_galore.yml](../environments/trim_galore.yml) |
| [01.2_mix_reads.sh](./01.2_mix_reads.sh) | Downsampling, read annotation, read mixing | [seqkit.yml](../environments/seqkit.yml) |
