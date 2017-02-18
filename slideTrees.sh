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


#chmod u+x */*.sh

#for i in mAus mCil mLuc mOcc mSep mThy mViv mYum
#do
#    cd $i
#    ./qsub.sh
#    cd ..
#done


#this loop will (1) create sliding windows across the genomes
#               (2) extract the seq
#               (3)and create files for alignment

#set window size and slide
WINDOW=1000000
SLIDE=100000

rm  /lustre/scratch/roplatt/refAssem/unaligned/*.fas

for SPECIES in mAus mCil mLuc mOcc mSep mThy mViv mYum
do

    #move into the species directory
    cd $SPECIES

    #--------  Sliding windows -----------#
    #index the genome, then create BED sliding window intervals
    echo "$SPECIES: (1) SAMTOOLS FAIDX"
    samtools faidx $SPECIES.refMasked.fa
    echo "$SPECIES: (2) BEDTOOLS MAKEWINDOWS"
    bedtools makewindows -g $SPECIES.refMasked.fa.fai -w $WINDOW -s $SLIDE >$SPECIES.slideWindow.bed
    
    #filter out intervales that are less than 1M bp in length
    echo "$SPECIES: (3) Filter intervals <1M"
    cat $SPECIES.slideWindow.bed | awk '{ if ($3-$1>=1000000) print $0}' >$SPECIES.slideWindow.sizeFiltered.bed

    #extract the window sequences in tab-delimited format
    echo "$SPECIES: (4) BEDTOOLS GETFASTA"
    bedtools getfasta -tab -fi $SPECIES.refMasked.fa -bed $SPECIES.slideWindow.sizeFiltered.bed -fo $SPECIES.slideWindow.sizeFiltered.tab
    
    #create a subdir for all of the extracted sequences
    mkdir sequences
    
    #and then create an new file for each sequence
    echo "$SPECIES: (5) AWK parse sequences"
    awk '{print ">"$1"\n"$2>"sequences/"$1".fas"}' <$SPECIES.slideWindow.sizeFiltered.tab

    #change the name of each seqeunce to include the species name (for downstream phylo)
    echo "$SPECIES: (6) SED modify sequence names"
    sed -i "s/GL/$SPECIES.GL/" sequences/GL*.fas

   
    cd sequences
   
    #then add the individual window sequences to files in the alignments subdir
    #  this file will eventually contain 1 sequence for each taxa (and need to be aligned).
    echo "$SPECIES: (7) CAT to alignment files"
    for i in GL*.fas
    do
        cat $i >>../../unaligned/$i
    done
    cd ..

    #space is limited so remove the tab and sequence files.    
    echo "$SPECIES: (9) Housekeeping"    
    rm $SPECIES.slideWindow.sizeFiltered.tab
    tar -czf sequences.tgz sequences &
    
    cd ..
done
    
#####################
# intermediate files:
#   $SPECIES.slideWindow.sizeFiltered.tab
#####################

mkdir aligned

cd unaligned

for UNALIGNED in *.fas
do

    ALIGNED=$(basename $UNALIGNED .fas)
    mafft --retree 1 --thread 10 --maxiterate 2 --fft $UNALIGNED >../aligned/$ALIGNED.mafft.fas

    cd ../aligned
    bash /lustre/work/apps/RAxML/usefulScripts/convertFasta2Phylip.sh $ALIGNED.mafft.fas >$ALIGNED.mafft.phy
    mpirun --mca mtl ^psm -np 10 raxmlHPC-MPI -m GTRCAT -p 12345 -x 12345 -# 1000 -s $ALIGNED.mafft.phy -n $ALIGNED

    cd ../unaligned

done
    
    
    
    
    
    
    
    
    
   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
