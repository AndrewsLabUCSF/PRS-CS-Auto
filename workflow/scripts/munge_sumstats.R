library(tidyverse)
library(MungeSumstats)

input_path <- snakemake@input[[1]]
output_path <- snakemake@output[[1]]
ref_genome <- snakemake@params[["ref_genome"]]
log_folder <- snakemake@params[["log_folder"]]

data(sumstatsColHeaders) #Precomputed
# sumstatsColHeaders <- readRDS("results/Updated_sumstatsColHeaders.rds")

message("\nReading in sumstats: ", input_path)
ss <- read_sumstats(
  input_path,
  nThread = 1,
  nrows = Inf,
  standardise_headers = FALSE,
  mapping_file = sumstatsColHeaders
)

out <- MungeSumstats::format_sumstats(
  path = input_path,
  ref_genome = NULL,
  convert_ref_genome = NULL,
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

message("\nExporting sumstats: ", output_path)
write_sumstats(out$sumstats, save_path = output_path)
