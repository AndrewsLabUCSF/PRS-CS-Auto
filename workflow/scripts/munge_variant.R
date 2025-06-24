#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(readr);  library(dplyr);  library(janitor);  library(tibble)
  library(GWASBrewer);  library(MungeSumstats)
})

# ─────────────────────────  Snakemake handles  ──────────────────────────
variant_file <- snakemake@input[["variant"]]      # .pvar or .bim
out_map      <- snakemake@output[["name_file"]]   # e.g. resources/<cohort>/<cohort>_cpra2rsids.txt
geno_prefix  <- snakemake@params[["geno_prefix"]] # prefix that has .fam/.psam

# ───────────────────────────  Helpers  ──────────────────────────────────
read_variant <- function(path) {
  switch(
    tools::file_ext(path),
    pvar = read_tsv(path, show_col_types = FALSE)            %>% 
           clean_names()                                     %>% 
           rename(chrom = number_chrom),
    bim  = read_tsv(path, col_names = FALSE, show_col_types = FALSE) %>% 
           setNames(c("chrom", "id", "cm", "pos", "alt", "ref")),
    stop("Unsupported variant file ‘", path, "’")
  )
}

# Get sample size from .fam or .psam rows (minus header for .psam)
get_N <- function(prefix) {
  fam  <- paste0(prefix, ".fam")
  psam <- paste0(prefix, ".psam")
  if      (file.exists(fam))  as.integer(system(paste("wc -l < ", fam ), intern = TRUE))
  else if (file.exists(psam)) as.integer(system(paste("wc -l < ", psam), intern = TRUE)) - 1L
  else                        1000L             # safe fallback
}

# ────────────────────── 1 ─ Read variant table ──────────────────────────
tbl <- read_variant(variant_file) %>%
       rename(SNP = id)            # make sure an “ID” column exists

# ────────────────────── 2 ─ Simulate dummy stats ────────────────────────
N <- as.numeric(get_N(geno_prefix))               # robust numeric N

sim <- GWASBrewer::sim_mv(
  G      = 1,
  N      = N,
  J      = nrow(tbl),
  h2     = 0.50,
  pi     = 0.01,
  est_s  = TRUE
)

full <- bind_cols(
  tbl,
  beta = as.numeric(sim$beta_hat[, 1]),
  se   = as.numeric(sim$se_beta_hat[, 1])
) %>%
  mutate(
    Z = beta / se,
    P = 2 * (1 - pt(abs(Z), Inf))
  )

# ─────────────── 3 ─ Munge (skip heavy reference-checks) ────────────────
# Write to temp-file because MungeSumstats reads from disk
tmp <- tempfile(fileext = ".tsv.gz")
write_tsv(full, tmp)

std <- MungeSumstats::format_sumstats(
  path              = tmp,
  ref_genome        = "GRCh38",
  return_data       = TRUE,
  bi_allelic_filter = FALSE,
  dbSNP             = 144,
  allele_flip_check = FALSE,
  indel             = FALSE,
  save_path         = out_map
)

# ────────────────────── 4 ─ Write CPRA → RSID map ───────────────────────
std %>% select(ID, SNP) %>% write_tsv(out_map, col_names = FALSE)