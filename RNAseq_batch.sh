#!/bin/bash

#SBATCH --job-name="RNA"
#SBATCH -p shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --time=20:00:00  
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
##SBATCH --mail-type=END,FAIL
##SBATCH --mail-user=zzhao121@jh.edu #  if you want email notification, this doesn't work that well imo

######----------------------------------------------------------------------------------########
######    Please copy the script then modify sample list and input directory below      ########
######    This script turns fastqs to bams, I usually do 3-5 samples for each run       ########
######    After modification, run these two commands to submit the script               ########
######    1.    chmod +x RNAseq_batch.sh                                                ########
######    2.    sbatch RNAseq_batch.sh                                                  ########
######----------------------------------------------------------------------------------########

echo "[$(date)] Job started on $(hostname)"

# Module and conda setup
module reset
module load anaconda/2023.03
eval "$(conda shell.bash hook)"

# Sample list definition 
######---------------------------------------------------------------------------#######
###### please modify for each run, only include characters BEFORE 'R1' and 'R2'  #######
######---------------------------------------------------------------------------#######

samples=(
    "NN11_S15_L004" 
    "NN31_S16_L004" 
    "NN23_S17_L004" 
    "NN02_S18_L004" 
    "NN21_S19_L004"
)

# Directories and reference
######-------------------------------------------------------------------------------------#######
###### please modify INPUT_DIR for each run, do NOT include forward slash (/)              #######
######-------------------------------------------------------------------------------------#######

INPUT_DIR="/dcs07/sunlab/data/Jen/SS37_Nian_RNA-seq/sctc_206717"
# this line below is for reference genome, don't need to modify unless you want something other than hg38
ref_genome="/dcs07/sunlab/data/Transfer_dc01/refgenome/GRCh38/hg38"
mkdir -p trimmed bam

for prefix in "${samples[@]}"; do
  echo "[$(date)] Processing sample: $prefix"

  # --- Step 0: Identify input reads flexibly ---
  echo "[$(date)] Searching for input FASTQ files..."
  R1_file=$(ls "${INPUT_DIR}"/"${prefix}"*R1*.fastq.gz | head -n 1 || true)
  R2_file=$(ls "${INPUT_DIR}"/"${prefix}"*R2*.fastq.gz | head -n 1 || true)
  if [[ -z "${R1_file}" || -z "${R2_file}" ]]; then
    echo "[$(date)] ERROR: Missing FASTQ files for ${prefix}"
    continue
  fi
  echo "[$(date)] Found R1: ${R1_file}"
  echo "[$(date)] Found R2: ${R2_file}"

  # --- Step 1: Adapter/Quality Trimming ---
  echo "[$(date)] Starting TrimGalore..."
  conda activate TrimGalore
  trim_galore --cores 4 --phred33 --stringency 4 --paired \
    --fastqc "${R1_file}" "${R2_file}" \
    -o ./trimmed 2>> "${prefix}_trim.log"
  conda deactivate
  echo "[$(date)] TrimGalore complete"

  # Find trimmed outputs: 
  trimmed_R1=$(ls trimmed/"$(basename "$R1_file" .gz | sed 's/\.fastq$//')"_val_1.fq.gz 2>/dev/null || ls trimmed/"${prefix}"*_val_1.fq.gz | head -n 1)
  trimmed_R2=$(ls trimmed/"$(basename "$R2_file" .gz | sed 's/\.fastq$//')"_val_2.fq.gz 2>/dev/null || ls trimmed/"${prefix}"*_val_2.fq.gz | head -n 1)
  if [[ ! -f "$trimmed_R1" || ! -f "$trimmed_R2" ]]; then
    echo "[$(date)] ERROR: Trimmed files not found for $prefix"
    continue
  fi

  # --- Step 2: Alignment ---
  echo "[$(date)] Starting alignment (hisat2)..."
  conda activate hisat2
  hisat2 -p 10 --rna-strandness RF -x "$ref_genome" \
    -1 "$trimmed_R1" \
    -2 "$trimmed_R2" \
    -S "${prefix}.sam" 2>> "${prefix}_hisat2.log"
  conda deactivate
  echo "[$(date)] Alignment complete"

  # --- Step 3: SAM to BAM and Sorting ---
  echo "[$(date)] Starting SAM to sorted BAM conversion (samtools)..."
  conda activate samtools
  samtools view -@ 8 -bhS "${prefix}.sam" > "${prefix}.bam"
  samtools sort -@ 8 "${prefix}.bam" -o "${prefix}_sorted.bam"
  conda deactivate
  echo "[$(date)] SAM to BAM and sorting complete"

  # --- Step 4: Add Read Group Info ---
  echo "[$(date)] Adding read groups (picard)..."
  conda activate picard
  picard AddOrReplaceReadGroups \
    I="${prefix}_sorted.bam" \
    O="${prefix}_RG_sorted.bam" \
    RGID="${prefix}" RGLB="lib1" RGPL="ILLUMINA" RGPU="unit1" RGSM="${prefix}" \
    SO=coordinate CREATE_INDEX=true 2>> "${prefix}_picard.log"
  echo "[$(date)] Read group info added"

  # --- Step 5: Deduplication ---
  echo "[$(date)] Removing duplicates (picard)..."
  picard MarkDuplicates \
    I="${prefix}_RG_sorted.bam" \
    O="bam/${prefix}_final.bam" \
    M="bam/${prefix}_final_metrics.txt" \
    CREATE_INDEX=true REMOVE_DUPLICATES=true 2>> "${prefix}_picard.log"
  conda deactivate
  echo "[$(date)] Deduplication complete"

  # --- Step 6: Clean-up and Organization ---
  echo "[$(date)] Cleaning intermediate files..."
  rm -v "${prefix}.sam" "${prefix}.bam" "${prefix}_sorted.bam"
  rm -v "${prefix}_RG_sorted.bam" "${prefix}_RG_sorted.bai"
  echo "[$(date)] $prefix processing finished"
done

echo "[$(date)] All samples processed into bam."

