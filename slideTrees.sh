mkdir refAssemGenomes
cp /lustre/scratch/daray/pseudo_it/*_wgs/*gatk.iteration4.consensus.FINAL.fa refAssemGenomes/
cp /lustre/scratch/daray/pseudo_it/reference/myoLuc2.fa refAssemGenomes/
chmod a-w refAssemGenomes/*


wget http://repeatmasker.org/genomes/myoLuc2/RepeatMasker-rm405-db20140131/myoLuc2.fa.out.gz
zcat myoLuc2.fa.out.gz |sed 1,3d  | awk '{print $5"\t"$6"\t"$7}' >myoLuc2_RM.bed



for i in  refAssemGenomes/*.fa
do

    REF_GENOME=$(basename $i)
    SPECIES_ABBREV=$(echo $REF_GENOME | cut -c 1-4)

    #mkdir $SPECIES_ABBREV
    cd $SPECIES_ABBREV

    #ln -s ../$i     

    #--------  Mask from RepeatMasker.org -----------#
    bedtools maskfasta -fi $REF_GENOME -fo $SPECIES_ABBREV.refMasked.fa -bed ../myoLuc2_RM.bed &


    #--------  Mask from RepeatMasker -----------#
    /lustre/work/daray/software/faToTwoBit \
        $SPECIES_ABBREV.refMasked.fa \
        $SPECIES_ABBREV.refMasked.2bit

    #/lustre/work/daray/software/generateSGEClusterRun_Chewie.pl \
        -twoBit $SPECIES_ABBREV.refMasked.2bit \
        -batch_count 10 \
        -species "Chiroptera" \
        -genomeDir .


    #chmod u+x qsub.sh doLift.sh




    cd ..
done



for i in mAus mCil mOcc mSep mThy mViv mYum
do
    cd $i
    ./qsub.sh
    cd ..
done



    #--------  Sliding windows -----------#
    #samtools faidx $REF_GENOME
    #bedtools makewindows -g $REF_GENOME.fai -w 1000000 -s 100000 >$SPECIES_ABBREV.slidWindow_1M-10K.bed

    #bedtools get fasta
