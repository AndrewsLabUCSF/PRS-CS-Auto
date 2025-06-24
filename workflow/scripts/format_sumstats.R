#!/usr/bin/env Rscript
library(tidyverse)
library(MungeSumstats)

# Snakemake inputs/outputs
input_path  <- snakemake@input[[1]]
output_path <- snakemake@output[[1]]
log_folder  <- snakemake@params[["log_folder"]]

data(sumstatsColHeaders)

message("\nReading in sumstats: ", input_path)
ss <- read_sumstats(
  input_path,
  nThread = 1,
  nrows    = Inf
)

# 1) Drop any existing SNP column
if ("SNP" %in% colnames(ss)) {
  message("Dropping existing 'SNP' column.")
  ss <- ss %>% select(-SNP)
}

# 2) Rename DBSNP_ID -> SNP
if ("DBSNP_ID" %in% colnames(ss)) {
  ss <- ss %>% rename(SNP = DBSNP_ID)
} else {
  stop("DBSNP_ID column not found.")
}

# 3) Optionally drop 'ID' if present
if ("ID" %in% colnames(ss)) {
  ss <- ss %>% select(-ID)
}

# 4) Rename alleles: ALT -> A1, REF -> A2
if (!("A1" %in% colnames(ss)) && "ALT" %in% colnames(ss)) {
  ss <- ss %>% rename(A1 = ALT)
}
if (!("A2" %in% colnames(ss)) && "REF" %in% colnames(ss)) {
  ss <- ss %>% rename(A2 = REF)
}

# 5) Rename ES -> BETA if needed
if (!("BETA" %in% colnames(ss)) && "ES" %in% colnames(ss)) {
  message("Renaming ES to BETA")
  ss <- ss %>% rename(BETA = ES)
}

# 6) Convert LP -> P if present
if ("LP" %in% colnames(ss)) {
  message("Converting LP to P")
  ss <- ss %>% mutate(P = 10^(-LP))
}

# 7) Determine which effect-size/stat columns to keep
required_cols <- c("SNP", "A1", "A2")
if (all(c("BETA", "SE") %in% colnames(ss))) {
  required_cols <- c(required_cols, "BETA", "SE")
} else if (all(c("BETA", "P") %in% colnames(ss))) {
  required_cols <- c(required_cols, "BETA", "P")
} else {
  stop("Need either (BETA & SE) or (BETA & P) in the data.")
}

# 8) Subset and export
message("Selecting columns: ", paste(required_cols, collapse = ", "))
ss_filtered <- ss %>% select(all_of(required_cols))

message("\nExporting sumstats to: ", output_path)
write_sumstats(ss_filtered, save_path = output_path)