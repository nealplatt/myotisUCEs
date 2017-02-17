################################################################################
#
#       Using ref guided genome assemblies to test for conflict across
#       several different genomes.
#
#
################################################################################

mkdir refAssemGenomes

#copy the reference and refGuided assemblies from DRay.
cp /lustre/scratch/daray/pseudo_it/*_wgs/*gatk.iteration4.consensus.FINAL.fa refAssemGenomes/
cp /lustre/scratch/daray/pseudo_it/reference/myoLuc2.fa refAssemGenomes/

#change permissions so I don't do anything stupid
chmod a-w refAssemGenomes/*

#get the RepeatMasker annotation and convert ot BED format
wget http://repeatmasker.org/genomes/myoLuc2/RepeatMasker-rm405-db20140131/myoLuc2.fa.out.gz
zcat myoLuc2.fa.out.gz |sed 1,3d  | awk '{print $5"\t"$6"\t"$7}' >myoLuc2_RM.bed


#Using a loop cycle through all assemblies and do two rounds of masking
#  First - mask using the RM annotation
#  Second - mask each using RepeatMasker
#
# Since small reads may map incorrectly to repeats, those SNPs may be innacurate
#    we don't want to consider those in our analysis.


for ASSEMBLY in  refAssemGenomes/*.fa
do

    REF_GENOME=$(basename $ASSEMBLY)
    SPECIES_ABBREV=$(echo $REF_GENOME | cut -c 1-4)

    # create a directory for each taxa    
    mkdir $SPECIES_ABBREV
    cd $SPECIES_ABBREV
    
    #soft link to the reference assembly
    ln -s ../$ASSEMBLY     

    
    # Hard mask assembly with RepeatMasker.org annotation
    bedtools maskfasta -fi $REF_GENOME -fo $SPECIES_ABBREV.refMasked.fa -bed ../myoLuc2_RM.bed


    # hard mask with repeat masker
    #/lustre/work/daray/software/faToTwoBit \
    #    $SPECIES_ABBREV.refMasked.fa \
    #    $SPECIES_ABBREV.refMasked.2bit &

    #/lustre/work/daray/software/generateSGEClusterRun_Chewie.pl \
    #    -twoBit $SPECIES_ABBREV.refMasked.2bit \
    #    -batch_count 10 \
    #    -species "Chiroptera" \
    #    -genomeDir . &

    cd ..
done

#####################
# intermediate files:
#   $SPECIES_ABBREV.refMasked.fa
#####################


chmod u+x */*.sh

for i in mAus mCil mLuc mOcc mSep mThy mViv mYum
do
    cd $i
    ./qsub.sh
    cd ..
done


#so the loop above creates a directory for each taxa.  The following runs in individual dirs

WINDOW=1000000
SLIDE=100000
for SPECIES in mAus mCil mLuc mOcc mSep mThy mViv mYum

    cd $SPECIES

    #--------  Sliding windows -----------#
    samtools faidx $SPECIES.refMasked.fa
    bedtools makewindows -g $SPECIES.refMasked.fa.fai -w $WINDOW -s $SLIDE >$SPECIES.slideWindow.bed
    
    cat $SPECIES.slideWindow.bed | awk '{ if ($3-$1>=1 000 000) print $0}' >$SPECIES.slideWindow.sizeFiltered.bed

    bedtools getfasta -tab -fi $SPECIES.refMasked.fa -bed $SPECIES.slideWindow.sizeFiltered.bed -fo $SPECIES.slideWindow.sizeFiltered.tab
    
   
    awk '{print ">"$1"\n"$2>"sequences/"$1".fas"}' <$SPECIES.slideWindow.sizeFiltered.tab


    sed -i "s/GL/$SPECIES.GL/" sequences/GL*.fas


    for i in 

  
        cat $i >>../alignments/$i



    cd ..
done
    
#####################
# intermediate files:
#   $SPECIES.slideWindow.sizeFiltered.tab
#####################
    
    
    
    
    
    
    
    
    
    
    awk '{print ">"$1"\n"$2>$1".fas"}' <test.tab
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
