import pandas as pd
import gzip

# File paths
input_file = "resources/Bellenguez2022load.chrall.CPRA_b37.tsv.gz"
output_file = "resources/Bellenguez2022load.chrall_b37_standardized.tsv.gz"

# Read compressed TSV file with error handling
with gzip.open(input_file, "rt", encoding="utf-8") as f:
        df = pd.read_csv(f, sep="\t", engine="python", dtype=str, on_bad_lines="skip", skiprows=7)

# Check column names before renaming
print("Original columns:", df.columns.tolist())

# Ensure both columns exist before renaming
if "OLD_ID" in df.columns and "ID" in df.columns:
    df = df.rename(columns={"ID": "PREV", "OLD_ID": "ID"})  # Rename ID -> PREV_ID, OLD_ID -> ID
elif "OLD_ID" in df.columns:  
    df = df.rename(columns={"OLD_ID": "ID"})  # Just rename OLD_ID -> ID
else:
    raise ValueError("ERROR: OLD_ID column not found. Cannot swap RSIDs.")

# Display updated column names
print("Updated columns:", df.columns.tolist())

# Save the modified DataFrame
df.to_csv(output_file, sep="\t", index=False, compression="gzip")

print(f"Swapped ID columns. Saved to: {output_file}")