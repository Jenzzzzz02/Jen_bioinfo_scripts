# Jen_bioinfo_scripts
A collection of SLURM workflows I used for my analyses

# RNAseq_batch.sh
this script processes raw fastq files into deduplicated bam files ready for other downstream analyses

expected input: pair-ended, stranded RNAseq fastq files with *R1* and *R2* as part of their names and ends with *fastq.gz
note that I used RF for hisat2 strandeness setting because our lab does a dUTP based libary prep 

# bigwig_batch.sh
this takes the output from RNAseq_batch.sh and process them into bigwig files ready for visualization on IGV

# make_feature_counts.sh
this takes the output from RNAseq_batch.sh and process them into gene count tables for DEG analysis

# run_rmats.sh
this takes the output from RNAseq_batch.sh as well as two sample metadata txt files and process them into RMATs output files, which describes alternative splicing events

# run_REDItools_know.sh
this takes the output from RNAseq_batch.sh and outputs tables of A to I editing events for each bam file. 
