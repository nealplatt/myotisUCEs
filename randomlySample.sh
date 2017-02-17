#number of randomly replicated alignments
SAMPLES=100

#number of loci in alignment
SAMPLE_SIZE=365

#directory to sample alignments from (this should be the 15_alignments dir)
ALIGNMENTS_DIR=/home/roplatt/myotisUCEs/neal/play/15_alignments

RAXML_BOOTREPS=100
RAXML_PROCESSORS=10

WORK_DIR=/home/roplatt/myotisUCEs/neal/play
BIN_DIR=/home/roplatt/myotisUCEs/neal/play/bin




cd $WORK_DIR
#approximatley 10% of all alignments
phyluce_align_randomly_sample_and_concatenate --nexus $ALIGNMENTS_DIR --output $WORK_DIR/randomSample --sample-size $SAMPLE_SIZE --samples $SAMPLES

#move these alignments into specific directories


cd $WORK_DIR/randomSample

for REPLICATE in $(seq 0 $(echo $SAMPLES-1 | bc))
do

    cd $WORK_DIR/randomSample

    mkdir "rep_"$REPLICATE"_FP_RAxML"

    cd "rep_"$REPLICATE"_FP_RAxML"

    mv ../META-random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.txt .
    mv ../random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex .

    #convert nexus to phylip and partitions
    NTAXA=$(cat random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex | grep dimensions | sed 's/.*ntax=\(.*\) .*/\1/')
    NCHAR=$(cat random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex | grep dimensions | sed 's/.*nchar=\(.*\);/\1/')


    sed -n -e '/begin sets/,$p' random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex >random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.charsets

    echo $NTAXA $NCHAR >random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.phylip
    cat random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex | grep -v ';\|#\|matrix' >>random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.phylip


    $BIN_DIR/raxml_nexusPartConvert.pl -m random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.charsets -r DNA | sed 's/\(DNA, \)\(.*\)\(uce-.*nexus\).*\(=.*$\)/\1 \3\4/' >random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.partitions

    #CMD="mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -f a -m GTRGAMMA -p $RANDOM -x $RANDOM -# $RAXML_BOOTREPS -s random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.phylip -n random-sample-"$REPLICATE"-$SAMPLE_SIZE"-rBoot" -q random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.partitions"
    #echo $CMD | qsub -N rand_"$REPLICATE"_raxml -o rand_"$REPLICATE"_raxml.o -e rand_"$REPLICATE"_raxml.e -P communitycluster -q Chewie -pe sm 10 -cwd -V -S /bin/bash

    cd $WORK_DIR/randomSample

done

######################################################################################################################################
#number of randomly replicated alignments
SAMPLES=100

#number of loci in alignment
SAMPLE_SIZE=365

#directory to sample alignments from (this should be the 15_alignments dir)
ALIGNMENTS_DIR=/home/roplatt/myotisUCEs/neal/play/15_alignments

RAXML_BOOTREPS=100
RAXML_PROCESSORS=10

WORK_DIR=/home/roplatt/myotisUCEs/neal/play
BIN_DIR=/home/roplatt/myotisUCEs/neal/play/bin




cd $WORK_DIR

for REPLICATE in $(seq 0 $(echo $SAMPLES-1 | bc))
do

    CMD="mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -f a -m GTRGAMMA -p $RANDOM -x $RANDOM -# $RAXML_BOOTREPS -s random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.phylip -n random-sample-"$REPLICATE"-$SAMPLE_SIZE"-rBoot" -q random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.partitions"
    echo $CMD | qsub -N rand_"$REPLICATE"_raxml -o rand_"$REPLICATE"_raxml.o -e rand_"$REPLICATE"_raxml.e -P communitycluster -q Chewie -pe sm 10 -cwd -V -S /bin/bash

    cd $WORK_DIR/randomSample

done
