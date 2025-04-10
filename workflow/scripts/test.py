import h5py

file_path = '/wynton/group/andrews/users/rakshyasharma/PRS/PRS-CS-Auto/resources/PRScs/ld_ref/ldblk_1kg_eur/ldblk_1kg_chr1.hdf5'

with h5py.File(file_path, 'r') as f:
    # List all groups (each representing an LD block)
    print("Top-level keys:", list(f.keys()))
    
    # For example, inspect the first block
    if 'blk_1' in f:
        blk1 = f['blk_1']
        print("Datasets in blk_1:", list(blk1.keys()))
        
        # Optionally, check a part of the LD matrix
        ld_matrix = blk1['ldblk'][()]
        print("Shape of ldblk in blk_1:", ld_matrix.shape)
        
        # Check the SNP list if available
        snplist = blk1['snplist'][()]
        print("Number of SNPs in blk_1:", len(snplist))