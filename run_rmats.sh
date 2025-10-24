#!/bin/bash
#SBATCH --job-name=rmats
#SBATCH -p shared
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --time=12:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

######----------------------------------------------------------------------------------########
######    Please copy the script then modify input files and directory below            ########
######    the input directory should contain all the bam files                          ########
######    after modification, run these two commands to submit the script               ########
######    1.    chmod +x run_rmats.sh                                                   ########
######    2.    sbatch run_rmats.sh                                                     ########
######----------------------------------------------------------------------------------########

# Load and activate environment
module reset
module load anaconda/2023.03
eval "$(conda shell.bash hook)"
conda activate rmats

# Input files
######----------------------------------------------------------------------------------------------------#######
###### please create 2 txt files that contains information about path to control and test bam files       #######
###### check /dcs07/sunlab/data/Jen/scripts/ for two example txt files I made                             #######
###### then, modify B1 and B2 with the path to the txt files you've made                                  #######
######----------------------------------------------------------------------------------------------------#######
B1="control.txt" ## use control for B1 
B2="treatment.txt" ## use treatment for B2
######---------------------------------------------------------------------------#######
###### please modify for each run, do NOT include forward slash '/' at the end   #######
######---------------------------------------------------------------------------#######
OUTDIR="/dcs07/sunlab/data/Jen/scripts/output"

# do not modify unless you want a different annotation file, this is for gencode hg38
GTF="/dcs07/sunlab/data/Jen/refgenome/hg38/gencode.v38.annotation.gtf"
# no need to modify this
TMPDIR="$OUTDIR/tmp"

# rmats version: v4.3.0

# Run rmats-turbo
mkdir -p "$OUTDIR" "$TMPDIR"

rmats.py \
    --gtf $GTF \
    --b1 $B1 \
    --b2 $B2 \
    --od $OUTDIR \
    --tmp $TMPDIR \
    --readLength 150 \
    --nthread 8 \
    --libType fr-firststrand \
    --task both \
    --novelSS \
    --variable-read-length \
    --individual-counts \
    -t paired

conda deactivate
#conda activate python
#python /dcs07/sunlab/data/Jen/scripts/filter_rmats.py -d $OUTDIR
#conda deactivate
