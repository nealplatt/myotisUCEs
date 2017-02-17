#GTST analyses


#copy file with branch labels and unlabeled to new directory

#compress all files in run



#Estimate trees (and bootstrap) for all at 15%

#the create directories for 25 35 45 55 65 75 85 95 100

#copy from the 15 trees into the others (reduce redundancy)


#from the working directory
cd /home/roplatt/myotisUCEs/neal/play

#create a directory for all gene trees with atleast 15% of taxa present.
mkdir 15_geneTrees
cd 15_geneTrees/

#convert all nexus files to phylip
phyluce_align_convert_one_align_to_another \
    --alignments ../15_alignments/ \
    --output 15_alignments_phylip \
    --input-format nexus \
    --output-format phylip-relaxed \
    --cores 10

WORK_DIR=/home/roplatt/myotisUCEs/neal/play

cd $WORK_DIR/15_geneTrees
#submit each locus to RAxML (fast bootstrapping) via the scheduler.
for i in $(ls 15_alignments_phylip/)
do

    UCE=$(basename $i .phylip-relaxed)
    CMD="raxmlHPC -f a -m GTRGAMMA -p $RANDOM -x $RANDOM -# 1000 -s ./15_alignments_phylip/$UCE.phylip-relaxed -n $UCE"-rBoot""
    echo $CMD | qsub -N $UCE -o $UCE.o -e $UCE.e -P communitycluster -q Chewie -pe fill 1 -cwd -V -S /bin/bash

done

#################
# once ALL RAxML runs are completed
################

cd $WORK_DIR/15_geneTrees

#use a for loop to populate gene trees for each %missing taxa (since all alignments with 37 taxa have 5, only the 15% needs to be run)
for i in 25 35 45 55 65 75 85 95 100
do

    mkdir $WORK_DIR/$i"_geneTrees"

    for UCE in $(ls $WORK_DIR/$i"_alignments"/ | sed 's/.nexus//')
        do
        cp "RAxML_bipartitions."$UCE"-rBoot" $WORK_DIR/$i"_geneTrees"
        done

done


mv 15_geneTrees 15_geneTrees_raxml
mkdir 15_geneTrees
cp 15_geneTrees_raxml/RAxML_bipartitions*-rBoot 15_geneTrees/
rm 15_geneTrees/*BranchLabels*






