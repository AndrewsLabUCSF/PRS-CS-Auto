library(tidyverse)
library(MungeSumstats)

input_path <- snakemake@input[[1]]
output_path <- snakemake@output[[1]]
#ref_genome <- snakemake@params[["ref_genome"]]
log_folder <- snakemake@params[["log_folder"]]

data(sumstatsColHeaders) #Precomputed
#data("sumstatsColHeaders", package = "MungeSumstats")
#print(colnames(sumstatsColHeaders)) 
#sumstatsColHeaders <- readRDS("results/Updated_sumstatsColHeaders.rds")


message("\nReading in sumstats: ", input_path)
ss <- read_sumstats(
  input_path,
  nThread = 1,
  nrows = Inf,
  standardise_headers = TRUE,
  mapping_file = sumstatsColHeaders
)

out <- MungeSumstats::format_sumstats(
  path = ss,
  ref_genome = "GRCh38",
  convert_ref_genome = NULL,
  dbSNP = 144,
  sort_coordinates = TRUE,
  return_data = TRUE,
  return_format = 'data.table',
  INFO_filter = 0,
  N_dropNA = TRUE,
  convert_small_p = FALSE,
  rmv_chr = NULL,
  snp_ids_are_rs_ids = FALSE,
  bi_allelic_filter = FALSE,
  force_new = TRUE,
  allele_flip_check = FALSE,
  log_folder = tempdir(),
  log_folder_ind = FALSE,
  log_mungesumstats_msgs = FALSE,
  compute_z = FALSE
) %>% as_tibble()

# Optionally, perform additional conversions if necessary:
if ("OR" %in% colnames(out)) {
  out <- out %>% mutate(BETA = log(OR))
}
if ("LP" %in% colnames(out)) {
  out <- out %>% mutate(P = 10^(-LP))
}

# Now, select only the required columns.
# Check if SE is available; if so, we assume BETA/SE format.
# Otherwise, if P is available, we assume BETA/P format.
required_cols <- c("SNP", "A1", "A2")
if ("SE" %in% colnames(out)) {
  required_cols <- c(required_cols, "BETA", "SE")
} else if ("P" %in% colnames(out)) {
  required_cols <- c(required_cols, "BETA", "P")
} else {
  stop("Neither SE nor P column found in the summary statistics.")
}

out <- out %>% select(all_of(required_cols))

message("\nExporting sumstats: ", output_path)
write_sumstats(out, save_path = output_path)
