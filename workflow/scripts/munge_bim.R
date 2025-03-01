# This script processes a .pvar file to create a mapping file (e.g., cpra2rsids.txt)
# and then calls plink2 to update the genotype file with new variant IDs.

library(readr)    # For read_tsv()
library(dplyr)    # For rename(), mutate(), bind_cols(), select()
library(janitor)  # For clean_names()
library(tibble)   # For as_tibble()
library(glue)     # For command string formatting
library(GWASBrewer)  # Used for simulating GWAS
library(MungeSumstats)  # Required for GWAS sumstats formatting
# Retrieve inputs, outputs, and parameters from Snakemake
input_pvar    <- snakemake@input[["pvar"]]       # e.g., "resources/ADGC/out.pvar"
output_snps   <- snakemake@output[["name_file"]]   # e.g., "resources/ADGC/cpra2rsids.txt"
plink_prefix  <- snakemake@params[["plink_prefix"]]  # e.g., "resources/ADGC/out"
plink_out     <- snakemake@params[["plink_out"]]     # e.g., "work/ADGC/adgc"


# 1. Read the .pvar file and clean column names
pvar.raw <- read_tsv(input_pvar) %>%
  janitor::clean_names() %>%
  rename(chrom = number_chrom)

# 2. Simulate GWAS summary statistics using GWASBrewer
dat_simple <- GWASBrewer::sim_mv(
  G = 1,        # simulation parameter: number of traits
  N = 500000,   # sample size
  J = nrow(pvar.raw), # number of variants
  h2 = 0.5,     # heritability
  pi = 0.01,    # proportion of causal variants
  est_s = TRUE, # estimate standard errors
  af = function(n){rbeta(n, 1, 5) }
)

# 3. Combine the pvar data with the simulated GWAS results
pvar <- bind_cols(
  pvar.raw, 
  dat_simple$beta_hat, 
  dat_simple$se_beta_hat, 
  dat_simple$snp_info
) %>%
  as_tibble() %>%
  rename(beta = '...6', se = '...7', ) %>%
  dplyr::select(-SNP) %>%
  mutate(
    Z = beta / se,
    P = 2 * (1 - pt(abs(Z), Inf))
  )
  
# 4. Reformat using MungeSumstats
reformatted <- MungeSumstats::format_sumstats(
  path = pvar,
  ref_genome = "GRCh38",
  return_data = TRUE,
  bi_allelic_filter = F,
  dbSNP = 144
)

# 5. Write the mapping file (e.g., cpra2rsids.txt) with selected columns
reformatted %>%
  as_tibble() %>%
  dplyr::select(ID, SNP) %>%
  write_tsv(output_snps, col_names = F)
