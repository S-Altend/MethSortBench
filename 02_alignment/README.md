# Cytosine-conversion-aware read alignment
In this subdirectory, generated human-mouse mixtures (refer [01_preprocessing/01.2_mix_reads.sh](../01_preprocessing/01.2_mix_reads.sh)) were aligned against the human (GRCh38) and mouse (GRCm38/mm10) reference genome required for *bamcmp* and XenofilteR read sorting.

## Nextflow Methylseq pipeline
The [nf-core/methylseq](https://github.com/nf-core/methylseq) (v4.1.0-gdb60bfe) pipeline implemented in Nextflow (v25.10.0) was adopted for WGBS read alignment due to its reproducible, community-maintained workflow. Alignment was performed using the bwameth aligner (v0.2.9) with the BWA-MEM2 backend.

Adapter trimming was skipped within the pipeline (*--skip_trimming*), as reads had been preprocessed uniformly prior to mixture generation (refer [01_preprocessing/01.1_trim_galore.sh](../01_preprocessing/01.1_trim_galore.sh)). The *–fasta* parameter was set to the appropriate reference build for each species (GRCh38.p14 and GRCm38 from NCBI RefSeq). Post-alignment processing, including sorting and indexing, was performed using samtools (v1.21).

## Scripts

| Script                                                           | Usage                                                                             | Requirements                                         |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------- | ---------------------------------------------------- |
| [02.1_methylseq_samplesheet.py](./02.1_methylseq_samplesheet.py) | Create methylseq samplesheet (sample, fastq_1, fastq_2) as input for the pipeline | [data_science.yml](../environments/data_science.yml) |
| [02.2_methylseq_human.sh](./02.2_methylseq_human.sh)             | WGBS alignment against the human reference genome                                 | [nextflow.yml](../environments/nextflow.yml)         |
| [02.2_methylseq_mouse.sh](./02.2_methylseq_mouse.sh)             | WGBS alignment against the mouse reference genome                                 | [nextflow.yml](../environments/nextflow.yml)         |
| [02.3_methylseq_move_bam.py](./02.3_methylseq_move_bam.py)       | Move and organise output BAM files from the methylseq pipeline                    | [data_science.yml](../environments/data_science.yml) |
