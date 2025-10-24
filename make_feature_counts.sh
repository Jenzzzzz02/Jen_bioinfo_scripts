#!/bin/bash

#SBATCH --job-name="feature"
#SBATCH -p shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=10:00:00
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
##SBATCH --mail-type=END,ALL
##SBATCH --mail-user=zzhao121@jh.edu

module reset
module load anaconda/2023.03
######----------------------------------------------------------------------------------########
######    Please copy the script then modify input directory below                      ########
######    the input directory should contain all the bam files                          ########
######    after modification, run these two commands to submit the script               ########
######    1.    chmod +x make_feature_counts.sh                                         ########
######    2.    sbatch make_feature_counts.sh                                           ########
######----------------------------------------------------------------------------------########

# Define variables
######---------------------------------------------------------------------------#######
###### please modify for each run, do NOT include forward slash '/' at the end   #######
######---------------------------------------------------------------------------#######
INPUT_DIR="/dcs07/sunlab/data/Jen/SS37_Nian_RNA-seq/bam"
OUTPUT_DIR="/dcs07/sunlab/data/Jen/SS37_Nian_RNA-seq/feature_counts"

#do not modify unless you want to use another annotation file, this is gencode for hg38
GTF_FILE="/dcs07/sunlab/data/Transfer_dc01/refgenome/GRCh38/gencode.v38.annotation.gtf"

# Setup
eval "$(conda shell.bash hook)"
conda activate subread

# Prepare output directories
mkdir -p "$OUTPUT_DIR"
cd "$INPUT_DIR"

# Run featureCounts
featureCounts -t exon -g gene_id \
    -p -T 8 -B -s 0 \
    -a "$GTF_FILE" \
    -o "$OUTPUT_DIR/counts_ID.txt" *.bam
featureCounts -t exon -g gene_name \
    -p -T 8 -B -s 0 \
    -a "/dcs07/sunlab/data/Transfer_dc01/refgenome/GRCh38/gencode.v38.annotation.gtf" \
    -o "$OUTPUT_DIR/counts_name.txt" *.bam
