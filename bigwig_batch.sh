#!/bin/bash

#SBATCH --job-name="bw"
#SBATCH -p shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=50G
#SBATCH --time=10:00:00
#SBATCH --output=%x_%A.out
#SBATCH --error=%x_%A.err
##SBATCH --mail-type=END,ALL
##SBATCH --mail-user=zzhao121@jh.edu

######----------------------------------------------------------------------------------########
######    Please copy the script, then modify the input directory and sample list below ########
######    do all samples at once for convenience, or do batches for quicker processing  ########
######    after modification, run these two commands to submit the script               ########
######    1.    chmod +x bigwig_batch.sh                                                ########
######    2.    sbatch bigwig_batch.sh                                                  ########
######----------------------------------------------------------------------------------########

module reset
module load anaconda/2023.03
eval "$(conda shell.bash hook)"
conda activate deeptools


mkdir -p bigwig
mkdir -p logs

# path to bam directory
######---------------------------------------------------------------------------#######
###### please modify for each run, do NOT include forward slash '/' at the end   #######
######---------------------------------------------------------------------------#######
INPUT_DIR="./bam"
# list of bam files to process
######---------------------------------------------------------------------------#######
###### please modify for each run, include the ENTIRE name of the files          #######
######---------------------------------------------------------------------------#######
sample_list=(
  "NN12_S27_L004_final.bam"
  "NN13_S20_L004_final.bam"
  "NN14_S2_L004_final.bam"
  "NN15_S5_L004_final.bam"
  "NN16_S33_L004_final.bam"
  "NN17_S25_L004_final.bam"
  "NN18_S30_L004_final.bam"
  "NN19_S9_L004_final.bam"
)

for INPUT_FILE in "${sample_list[@]}"; do
    prefix="${INPUT_FILE%%_final.bam}"
    echo "Processing $INPUT_FILE ..."
    if [ ! -f "$INPUT_DIR/$INPUT_FILE" ]; then
      echo "Warning: $INPUT_FILE not found, skipping" >&2
      continue
    fi
    bamCoverage -p 6 --normalizeUsing RPKM \
        --binSize 1 -b "$INPUT_DIR/$INPUT_FILE" --filterRNAstrand reverse \
        -o "./bigwig/${prefix}.RPKM.reverse.bw"

    bamCoverage -p 6 --normalizeUsing RPKM \
        --binSize 1 -b "$INPUT_DIR/$INPUT_FILE" --filterRNAstrand forward \
        -o "./bigwig/${prefix}.RPKM.forward.bw"
done
echo "all samples processed"
conda deactivate
