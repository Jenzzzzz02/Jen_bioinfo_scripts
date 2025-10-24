#!/bin/bash
#SBATCH --job-name=redi
#SBATCH -p shared
#SBATCH --cpus-per-task=6
#SBATCH --mem=30G
#SBATCH --time=10:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

# Set temp directory
TMPDIR="/dcs07/sunlab/data/Jen/tmp"
mkdir -p "$TMPDIR" || { echo "Failed to create TMPDIR"; exit 1; }
export _JAVA_OPTIONS="-Djava.io.tmpdir=$TMPDIR"

# Load environment
module reset
module load anaconda/2023.03
module load samtools
module load java/17
eval "$(conda shell.bash hook)"
conda activate REDItools

# List of BAM files
sample_list=(
  "TCM02_S15_L007"
  "TCM03_S2_L007"
  "TCM04_S40_L007"
  "TCM05_S33_L007"
  "TCM06_S20_L007"
  "TCM07_S25_L007"
  "TCM08_S8_L007"
)
bam_dir="/dcs07/sunlab/data/SS40_TCM_RNA-seq/bam"
for sample in "${sample_list[@]}"; do
    mkdir -p ${sample}_table
    python /dcs07/sunlab/data/Jen/ADAR3/rna_editing_protocol/REDItools/main/REDItoolKnown.py \
        -i "${bam_dir}/${sample}_final.bam" \
        -f "/dcs07/sunlab/data/Jen/refgenome/hg38/hg38.fa" \
        -l "/dcs07/sunlab/data/Jen/refgenome/hg38/TABLE1_hg38_v2_sorted.txt.gz" \
        -o "${sample}_table" \
        -t 6 \
        -m 60 \
        -s 2
    mv "${sample}_table/known_"* "${sample}_table/editing"
    mv "${sample}_table/editing/outTable_"* "${sample}_table/editing/${sample}.outTable.txt"
done
