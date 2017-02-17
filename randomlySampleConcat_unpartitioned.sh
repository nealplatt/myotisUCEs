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


#run species tree analysis
cp -r $WORK_DIR/15_geneTrees .


for REPLICATE in $(seq 0 $(echo $SAMPLES-1 | bc))
do

    cd $WORK_DIR/randomSample

    mkdir "rep_"$REPLICATE"_astral"

    cd "rep_"$REPLICATE"_astral"

    mv ../META-random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.txt .
   

    cat $(sed 's/\/.*\/\(uce.*\).nexus/\1/gi' META-random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.txt |awk '{print "../15_geneTrees/RAxML_bipartitions."$1"-rBoot"}') >random-sample-"$REPLICATE"-$SAMPLE_SIZE.geneTrees



    #build astral tree
    POSTPROB_CMD="java -jar $BIN_DIR/ASTRAL/astral.4.10.6.jar --input random-sample-"$REPLICATE"-$SAMPLE_SIZE.geneTrees --branch-annotate 3 --output random-sample-"$REPLICATE-$SAMPLE_SIZE"_ASTRAL_posteriorProbability.tree"
    FULLANNO_CMD="java -jar $BIN_DIR/ASTRAL/astral.4.10.6.jar --input random-sample-"$REPLICATE"-$SAMPLE_SIZE.geneTrees --branch-annotate 2 --output random-sample-"$REPLICATE-$SAMPLE_SIZE"_ASTRAL_fullAnnotation.tree" 
    QUARTSUP_CMD="java -jar $BIN_DIR/ASTRAL/astral.4.10.6.jar --input random-sample-"$REPLICATE"-$SAMPLE_SIZE.geneTrees --branch-annotate 1 --output random-sample-"$REPLICATE-$SAMPLE_SIZE"_ASTRAL_quartetSupport.tree"  

    #submit to scheduler
    echo $POSTPROB_CMD | qsub -N rep$REPLICATE-astral_PosProb -o rep$REPLICATE-astral_PosProb.log -e rep$REPLICATE-astral_PosProb.err -P communitycluster -q R2D2 -pe fill 1 -cwd -V -S /bin/bash
    echo $FULLANNO_CMD | qsub -N rep$REPLICATE-astral_FullAno -o rep$REPLICATE-astral_FullAno.log -e rep$REPLICATE-astral_FullAno.err -P communitycluster -q R2D2 -pe fill 1 -cwd -V -S /bin/bash
    echo $QUARTSUP_CMD | qsub -N rep$REPLICATE-astral_Quartet -o rep$REPLICATE-astral_Quartet.log -e rep$REPLICATE-astral_Quartet.err -P communitycluster -q R2D2 -pe fill 1 -cwd -V -S /bin/bash

   

    #wait a bit so we don't over submit and sap all of the mem/cpu resources
    sleep 60


    cd $WORK_DIR/randomSample
done

########################################################################################################################



#run concatenated analyses
for REPLICATE in $(seq 0 $(echo $SAMPLES-1 | bc))
do

    cd $WORK_DIR/randomSample

    mkdir "rep_"$REPLICATE"_up_raxml"

    cd "rep_"$REPLICATE"_up_raxml"

    mv ../random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex .

    #convert nexus to phylip and partitions
    NTAXA=$(cat random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex | grep dimensions | sed 's/.*ntax=\(.*\) .*/\1/')
    NCHAR=$(cat random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex | grep dimensions | sed 's/.*nchar=\(.*\);/\1/')



    echo $NTAXA $NCHAR >random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.phylip
    cat random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.nex | grep -v ';\|#\|matrix' >>random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.phylip



    CMD="mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -f a -m GTRGAMMA -p $RANDOM -x $RANDOM -# $RAXML_BOOTREPS -s random-sample-"$REPLICATE"-$SAMPLE_SIZE-loci.phylip -n random-sample-"$REPLICATE"-"$SAMPLE_SIZE"-rBoot"
    echo $CMD | qsub -N rand_"$REPLICATE"_raxml -o rand_"$REPLICATE"_raxml.o -e rand_"$REPLICATE"_raxml.e -P communitycluster -q Chewie,R2D2 -pe sm 10 -cwd -V -S /bin/bash

    cd $WORK_DIR/randomSample

done

