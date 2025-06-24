#!/bin/bash

# Usage:
#   chmod +x ./workflow/scripts/subset_habshd_adgc.sh
#   module load CBI plink

# Example:
#   ./workflow/scripts/subset_habshd_adgc.sh /wynton/group/andrews/data/adgc/cleaned/out /wynton/group/andrews/data/habshd/results/imputed/all resources/HABSHD/HABSHD

# Exit on error
set -euo pipefail

# Input arguments
ADGC=$1
HABSHD=$2
OUT=$3

echo "=== Subsetting HABSHD to match ADGC cohort ==="
echo "ADGC prefix:      $ADGC"
echo "HABSHD prefix:    $HABSHD"
echo "Output prefix:    $OUT"


echo "[1/3] Extracting SNP list from $ADGC..."
plink --bfile "$ADGC" --write-snplist --out "${OUT}_snps"

# Step 2: Subset HABSHD to SNPs in ADGC
echo "[2/3] Subsetting $HABSHD to SNPs in ADGC..."
plink --bfile "$HABSHD" --extract "${OUT}_snps.snplist" --make-bed --out "${OUT}_snp_subset"

echo "=== Done ==="
echo "SNP-matched HABSHD bfiles written to:"
echo "  ${OUT}_snp_subset.bed"
echo "  ${OUT}_snp_subset.bim"
echo "  ${OUT}_snp_subset.fam"