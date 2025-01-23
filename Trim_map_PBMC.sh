#!/bin/bash
#SBATCH --mail-user=audrey.m.arner@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH -J Trim_map_PBMC        	   
#SBATCH -n 1                   
#SBATCH --cpus-per-task=2             
#SBATCH -t 0-10:10              
#SBATCH --mem=100GB
#SBATCH -o Trim_map_PBMC_round2_%A_%a.out     
#SBATCH -e Trim_map_PBMC_round2_%A_%a.err     
#SBATCH --array=1-375%25

#############################################
## script created by Audrey Arner 		   ## 
#############################################

# define input
barcode=`sed -n ${SLURM_ARRAY_TASK_ID}p /data/lea_lab/arneram/OA_files/OA_PBMCs_IDs_round2.txt`

module load Anaconda2/4.4.0

source activate RNAseq

R1=/data/lea_lab/archive_raw_fastq/OrangAsli_WGS_NovaSeqX_13Nov24/${barcode}_R1_001.fastq.gz
R2=/data/lea_lab/archive_raw_fastq/OrangAsli_WGS_NovaSeqX_13Nov24/${barcode}_R2_001.fastq.gz
R1_trim=/nobackup/lea_lab/arneram/OA_PBMC_round2/${barcode}.R1.trim.fastq.gz
R2_trim=/nobackup/lea_lab/arneram/OA_PBMC_round2/${barcode}.R2.trim.fastq.gz

cutadapt --nextseq-trim 20 -e 0.05 --overlap 2 -a "A{50}" -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -a AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -A AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT --minimum-length=20 --trim-n -o $R1_trim -p $R2_trim $R1 $R2

module purge

module load GCC/6.4.0-2.28 STAR/2.5.4b

STAR --genomeDir /nobackup/lea_lab/arneram/STARIndex --outFileNamePrefix /nobackup/lea_lab/arneram/tmp_OA_PBMC/${barcode}. --runThreadN 8 --outFilterMultimapNmax 1 --readFilesCommand zcat --readFilesIn $R1_trim $R2_trim --outSAMtype BAM SortedByCoordinate --sjdbGTFfile /data/lea_lab/shared/annotation/hg38.ncbiRefSeq.gtf --sjdbFileChrStartEnd /nobackup/lea_lab/arneram/STARIndex/sjdbList.out.tab

module purge

module load GCC/6.4.0-2.28  OpenMPI/2.1.1 HTSeq/0.9.1-Python-3.6.3

htseq-count -f bam -s no -m intersection-nonempty /nobackup/lea_lab/arneram/tmp_OA_PBMC/${barcode}.Aligned.sortedByCoord.out.bam /data/lea_lab/shared/annotation/hg38.ncbiRefSeq.gtf > /nobackup/lea_lab/arneram/counts/${barcode}.Aligned.counts
