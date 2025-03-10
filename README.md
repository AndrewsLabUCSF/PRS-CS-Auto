# Polygenic Risk Score (PRS) Continuous Shrinkage (CS) Pipeline Using Snakemake

## Overview

This Snakemake pipeline is designed for calculating polygenic risk scores (PRS) using PRS-CS Auto. It automates preprocessing of summary statistics, genotype data preparation, filtering with HapMap3 SNPs, scoring PRS, and removing the APOE region for Alzheimer's Disease research.

## Workflow Steps

1. **Munge Summary Statistics**

   - Converts raw summary statistics into a format compatible with PRS-CS Auto.
   - Container: `codewithrakshya/mungesumstats_docker`

2. **Process BIM/PVAR Files into PLINK Format**

   - Generates BED/BIM/FAM files from BIM/PVAR files.
   - Uses `plink.yaml` conda environment

3. **Prepare HapMap3 SNP List (Optional)**

   - Prepares a list of HapMap3 SNPs for filtering purposes.

4. **Filter Genotype Data**

   - Filters genotype data to include only HapMap3 SNPs.
   - Uses PLINK for SNP extraction.

5. **Run PRS-CS Auto**

   - Executes PRS-CS Auto for each chromosome.
   - Produces PRS weights for subsequent analysis.

6. **Concatenate Chromosome-Specific PRS Weights**

   - Concatenates PRS weights from all chromosomes into a single file.

7. **Remove APOE Region**

   - Removes SNPs located in the APOE region (chr19:44,408,822-45,408,822).

8. **Calculate PRS with PLINK**

   - Scores individuals based on concatenated PRS weights using PLINK.

## Prerequisites

- Snakemake v8.0+
- Singularity or Docker installed for containerized execution
- Conda environment set up for PLINK and PRS-CS (`envs/plink.yaml`, `envs/prscs.yaml`)

## Configuration

Edit parameters in `config/config.yaml`:

- Cohort information
- Paths to summary statistics files
- Paths for reference genomes and other necessary input files

## Execution

Run the pipeline using the command:

```bash
snakemake --use-conda --use-singularity --cores <num_cores>
```

## Directory Structure

```
├── config
│   └── config.yaml
├── envs
│   ├── plink.yaml
│   └── prscs.yaml
├── scripts
│   └── munge_sumstats.R
├── resources
│   └── (input files)
├── results
│   └── prscs_results
└── Snakefile
```

## Configuration (`config.yaml`)

Adjust paths, filenames, and parameters such as `ref_dir`, sample sizes, and chromosome lists directly within `config.yaml`.

## Troubleshooting

- Ensure containers and conda environments are correctly set up.
- Verify paths in `config.yaml` and availability of summary statistics and genotype files.

For issues, review Snakemake logs in `.snakemake/log/`.

---

For questions or support, please contact Rakshya Sharma.

