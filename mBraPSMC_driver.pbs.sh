#!/bin/bash
#$ -V
#$ -cwd
#$ -S /bin/bash
#$ -N mBraPSMC
#$ -o $JOB_NAME.o$JOB_ID
#$ -e $JOB_NAME.e$JOB_ID
#$ -q ray512cc
#$ -pe sm 20 
#$ -P communitycluster

#set up species specific variables
genome=mbrandtii.fasta
abbrev=mBra
#test

#make sure your genome file has no blank lines

sed '/^$/d' $genome >tempGenome
mv tempGenome $genome


#set up alias' for major programs
BWA_HOME=/lustre/work/apps/bwa-0.6.2/
SAMTOOLS_HOME=/lustre/work/apps/samtools-0.1.19/
PICARD_HOME=/lustre/work/apps/picard-tools-1.91/
BCFTOOLS_HOME=/lustre/work/apps/samtools-0.1.18/bcftools/
#fastq dump

################################################################################
# Step 1: Get data from SRA
################################################################################
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611188/SRR611188.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611187/SRR611187.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611186/SRR611186.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611185/SRR611185.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611184/SRR611184.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611183/SRR611183.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611182/SRR611182.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611181/SRR611181.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611180/SRR611180.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611179/SRR611179.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611178/SRR611178.sra
 #wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR611/SRR611177/SRR611177.sra



#convert .sra to fastq (gzipped)
#fastq-dump --split-files --gzip --outdir . ./*sra



################################################################################
# Step 2: Map reads to genome with BWA
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#initiate an array with the SRR##s to loop mapping
srr[0]=SRR611177
srr[1]=SRR611178
srr[2]=SRR611179
srr[3]=SRR611180
srr[4]=SRR611181
srr[5]=SRR611182
srr[6]=SRR611183
srr[7]=SRR611184
srr[8]=SRR611185
srr[9]=SRR611186
srr[10]=SRR611187
srr[11]=SRR611188

#init array with insertions sizes that correspond to the SRR from above
insSize[0]=170
insSize[1]=170
insSize[2]=500
insSize[3]=800
insSize[4]=2000
insSize[5]=2000
insSize[6]=5000
insSize[7]=5000
insSize[8]=10000
insSize[9]=10000
insSize[10]=20000
insSize[11]=20000

#use bwa to index the genome
#$BWA_HOME/bwa index $genome 



#===================
# initiate a loop to cycle through each SRR then
#	[1] map the R1 reads to the genome
#	[2] map the R2 reads to the genome
#	[3] calculate the max insertions size
#	[4] then creat a sorted bam file of mapped reads (r1 and r2)
#	[5] Remove duplicate reads


for (( i = 3; i < ${#srr[@]}; i++))
	do
	
	#===================
	# [1] Map the R1reads to the genome
	#$BWA_HOME/bwa aln 			\
		#-n 0.01 			\
		#-l 28 				\
		#-t 19 				\
		#-q 20				\
        	#-f $abbrev_${srr[$i]}_R1.sai 	\
		#$genome 			\
        	#${srr[$i]}_1.fastq.gz 
	
	#===================
	# [2] Map the R2reads to the genome
	#$BWA_HOME/bwa aln 			\
		#-n 0.01 			\
		#-l 28 				\
		#-t 19 				\
		#-q 20				\
       		#-f $abbrev_${srr[$i]}_R2.sai	\
		#$genome 			\
        	#${srr[$i]}_2.fastq.gz 

	#===================
	# [3] calculate the max insertion size
	maxInsSize=$((${insSize[$i]}*2))
	
	#===================
	# [4] use sampe and SAMtools to create a sorted bam file of mapped reads
	$BWA_HOME/bwa sampe 				\
		-a $maxInsSize 				\
		-f $abbrev"_"${srr[$i]}"_"SAMPE.sam 	\
		$genome 				\
		$abbrev"_"${srr[$i]}"_"R1.sai 		\
		$abbrev"_"${srr[$i]}_R2.sai 		\
		${srr[$i]}_1.fastq.gz k			\
		${srr[$i]}_2.fastq.gz 
		
	$SAMTOOLS_HOME/samtools view 			\
		-bS 					\
		-F 4 					\
		-q 20 					\
		-o $abbrev"_"${srr[$i]}"_"SAMPE.bam 	\
		$abbrev"_"${srr[$i]}"_"SAMPE.sam 
		
	$SAMTOOLS_HOME/samtools sort 			\
		-@ 19 					\
		$abbrev"_"${srr[$i]}_SAMPE.bam 		\
		$abbrev"_"${srr[$i]}"_"SAMPEsorted

	
	#===================
	# [5] remove sequencing duplicates from the sorted bam file w/ PICARD	
	java 						\
        	-Xmx24g 				\
		-Djava.io.tmpdir=tmp 			\
		-jar $PICARD_HOME/MarkDuplicates.jar 	\
        	I=$abbrev"_"${srr[$i]}_SAMPEsorted.bam 	\
       		O=$abbrev"_"${srr[$i]}_SAMPEnoDup.bam 	\
        	M=$abbrev"_"${srr[$i]}_dupMetric.out 	\
        	REMOVE_DUPLICATES=true 			\
		MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=100 	\
		VALIDATION_STRINGENCY=SILENT 		\
		ASSUME_SORTED=TRUE 			\
		TMP_DIR=tmp


	#rm $abbrev"_"${srr[$i]}"_"SAMPE.sam $abbrev"_"${srr[$i]}"_"SAMPE.bam

done

# merge all the bam files together 
$SAMTOOLS_HOME/samtools merge mBra_allMapped_SAMPE.bam *_SAMPEnoDup.bam
# rm *_SAMPEnoDup.bam





	$SAMTOOLS_HOME/samtools sort 			\
		-@ 19 					\
		$abbrev"_"${srr[$i]}_SAMPE.bam 		\
		$abbrev"_"${srr[$i]}"_"SAMPEsorted




$SAMTOOLS_HOME/samtools mpileup \
	-C50 \
	-R \
	-g \
	-f $genome \
	$abbrev"_allMapped_SAMPEsorted.bam" \
   | $BCFTOOLS_HOME/bcftools view \
		-c \
		-e \
		-g \
		-t 0.0002 \
		$abbrev"_allMapped_mPileUp.out" \
   | gzip > $abbrev"_allMapped_SNPs.vcf.gz"



       $BCFTOOLS_HOME/bcftools view -c -e -g -t 0.0002 mBra_allMapped_mPileUp.out >mBra_allMapped_SNPs.vcf
	



$SAMTOOLS_HOME/samtools mpileup \
	-C50 \
	-R \
	-g \
	-f $genome \
	mBra_allMapped_SAMPEsorted.bam \
	>mBra_allMapped_mPileUp.bcf




samtools mpileup \
      -C50 \
      -f <reference.genome.fa> \
       <rm.dups.bam> \
       |bcftools view -c -e -g -t 0.0002 - \
       |gzip > <snps.vcf.gz>








