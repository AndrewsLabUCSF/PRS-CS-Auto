library(tidyverse)
library(MungeSumstats)

input_path <- snakemake@input[[1]]
output_path <- snakemake@output[[1]]
log_folder <- snakemake@params[["log_folder"]]

data(sumstatsColHeaders)

message("\nReading in sumstats: ", input_path)
ss <- read_sumstats(
  input_path,
  nThread = 1,
  nrows = Inf
)

# Remove the existing 'SNP' column (which likely came from the first "ID" column)
if ("SNP" %in% colnames(ss)) {
  message("Dropping existing 'SNP' column to force use of DBSNP_ID as SNP.")
  ss <- ss %>% select(-SNP)
}

# Rename DBSNP_ID to SNP
if ("DBSNP_ID" %in% colnames(ss)) {
  ss <- ss %>% rename(SNP = DBSNP_ID)
} else {
  stop("DBSNP_ID column not found in the summary statistics.")
}

# (Optionally, you can remove the "ID" column as well, if still present)
if ("ID" %in% colnames(ss)) {
  ss <- ss %>% select(-ID)
}

# Now, define effect and non-effect alleles using ALT and REF:
if (!("A1" %in% colnames(ss)) & "ALT" %in% colnames(ss)) {
  ss <- ss %>% rename(A1 = ALT)
}
if (!("A2" %in% colnames(ss)) & "REF" %in% colnames(ss)) {
  ss <- ss %>% rename(A2 = REF)
}

# Handle LP column if present (convert LP to P)
if ("LP" %in% colnames(ss)) {
  ss <- ss %>% mutate(P = 10^(-LP))
}

# Define required columns; add BETA and SE or P based on availability
required_cols <- c("SNP", "A1", "A2")
if ("SE" %in% colnames(ss) & "BETA" %in% colnames(ss)) {
  required_cols <- c(required_cols, "BETA", "SE")
} else if ("P" %in% colnames(ss) & "BETA" %in% colnames(ss)) {
  required_cols <- c(required_cols, "BETA", "P")
} else {
  stop("Neither BETA/SE nor BETA/P columns found in the summary statistics.")
}

ss_filtered <- ss %>% select(all_of(required_cols))

message("\nExporting sumstats: ", output_path)
write_sumstats(ss_filtered, save_path = output_path)