cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning

mkdir alignments

phyluce_align_convert_one_align_to_another \
    --alignments ../mafft-gblocks-clean-55p-complete/ \
    --output ./alignments/ \
    --input-format nexus \
    --output-format phylip-relaxed \
    --cores 10


#rm qsub.sh
#rm -r /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/55pGeneTrees/*
#
#for PHYLIP_FILE in $(ls /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/alignments/*); 
#do 
#
#    UCE=$(basename $PHYLIP_FILE .phylip-relaxed)
#
#
#    mkdir ./55pGeneTrees/$UCE
#    cd ./55pGeneTrees/$UCE
#
#    ln -s $PHYLIP_FILE
#
#    echo '#!/bin/bash                                                                                                           '>$UCE-raxml-pbs.sh
#    echo "#$ -V                                                                                                                 ">>$UCE-raxml-pbs.sh
#    echo "#$ -cwd                                                                                                               ">>$UCE-raxml-pbs.sh
#    echo "#$ -S /bin/bash                                                                                                       ">>$UCE-raxml-pbs.sh
#    echo "#$ -N $UCE                                                                                                            ">>$UCE-raxml-pbs.sh
#    echo "#$ -o \$JOB_NAME.o\$JOB_ID                                                                                            ">>$UCE-raxml-pbs.sh
#    echo "#$ -e \$JOB_NAME.e\$JOB_ID                                                                                            ">>$UCE-raxml-pbs.sh
#    echo "#$ -q Chewie                                                                                                          ">>$UCE-raxml-pbs.sh
#    echo "#$ -pe fill 1                                                                                                         ">>$UCE-raxml-pbs.sh
#    echo "#$ -P communitycluster                                                                                                ">>$UCE-raxml-pbs.sh
#    echo "                                                                                                                      ">>$UCE-raxml-pbs.sh
#    echo "                                                                                                                      ">>$UCE-raxml-pbs.sh
#    echo "raxmlHPC -m GTRGAMMA -N 500 -p $RANDOM -n $UCE-bestGeneTree -s $UCE.phylip-relaxed                                    ">>$UCE-raxml-pbs.sh
#    echo "raxmlHPC -m GTRGAMMA -N 500 -p $RANDOM -n $UCE-bootGeneTree -s $UCE.phylip-relaxed -b $RANDOM                         ">>$UCE-raxml-pbs.sh
#    echo "raxmlHPC -m GTRGAMMA -f b -t RAxML_bestTree.$UCE-bestGeneTree -z RAxML_bootstrap.$UCE-bootGeneTree -n bestBoot.tree   ">>$UCE-raxml-pbs.sh 
#    echo "tar -cvzf runs-$UCE-bestGeneTree.tgz RAxML*bestGeneTree.RUN*                                                          ">>$UCE-raxml-pbs.sh 
#    echo "tar -cvzf runs-$UCE-bootGeneTree.tgz RAxML*bootGeneTree.RUN*                                                          ">>$UCE-raxml-pbs.sh 
#    echo "rm RAxML*RUN*                                                                                                         ">>$UCE-raxml-pbs.sh 
#
#    cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning
#
#    echo "cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/55pGeneTrees/$UCE"  >>qsub.sh
#    echo "qsub $UCE-raxml-pbs.sh"                                                                       >>qsub.sh
#    echo                                                                                                >>qsub.sh
#
#done



phyluce_align_convert_one_align_to_another \
    --alignments alignments_phylip/ \
    --output alignments_fasta \
    --input-format phylip-relaxed \
    --output-format fasta \
    --cores 3


mkdir genes_dir
cd genes_dir

#populate individual files for each gene according to the statistical binning readme
for i in $(ls ../alignments_fasta/)
    do

    base=$(basename $i .fasta)
    
    mkdir $base
    cd $base

    cp ../../55pGeneTrees/$base/RAxML_bipartitions.bestBoot.tree .
    cp ../../alignments_fasta/$i .
        
    cd ..

    done



#moved to local unix station
#had to edit all scripts to include
BIN_HOME=/home/neal/Dropbox/statisticalBinning

chmod u+x makecommands.compatibility.sh
./makecommands.compatibility.sh genes_dir 50 50p_pwise RAxML_bipartitions.bestBoot.tree

chmod u+x commmands.compat.50
sh ./commands.compat.50


cd [pairwise_output_dir]; 
ls| grep -v ge|sed -e "s/.50$//g" > genes   
python $BIN_HOME/cluster_genetrees.py genes 50


./build.supergene.alignments.sh 50p_pwise/ genes_dir/


###############################################################################################################################################################################
###############################################################################################################################################################################
###############################################################################################################################################################################
# finding and bootstrapping binnedGene trees for astral bootstrapping

/home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning

rm qsub.sh
rm -r /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/55pGeneTrees/*

for PHYLIP_FILE in $(ls /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/alignments/*); 
do 

    UCE=$(basename $PHYLIP_FILE .phylip-relaxed)


    mkdir ./55pGeneTrees/$UCE
    cd ./55pGeneTrees/$UCE

    ln -s $PHYLIP_FILE

    echo '#!/bin/bash                                                                                                           '>$UCE-raxml-pbs.sh
    echo "#$ -V                                                                                                                 ">>$UCE-raxml-pbs.sh
    echo "#$ -cwd                                                                                                               ">>$UCE-raxml-pbs.sh
    echo "#$ -S /bin/bash                                                                                                       ">>$UCE-raxml-pbs.sh
    echo "#$ -N $UCE                                                                                                            ">>$UCE-raxml-pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID                                                                                            ">>$UCE-raxml-pbs.sh
    echo "#$ -e \$JOB_NAME.e\$JOB_ID                                                                                            ">>$UCE-raxml-pbs.sh
    echo "#$ -q Chewie                                                                                                          ">>$UCE-raxml-pbs.sh
    echo "#$ -pe fill 1                                                                                                         ">>$UCE-raxml-pbs.sh
    echo "#$ -P communitycluster                                                                                                ">>$UCE-raxml-pbs.sh
    echo "                                                                                                                      ">>$UCE-raxml-pbs.sh
    echo "                                                                                                                      ">>$UCE-raxml-pbs.sh
    echo "raxmlHPC -m GTRGAMMA -N 100 -p $RANDOM -n $UCE-bestGeneTree -s $UCE.phylip-relaxed                                    ">>$UCE-raxml-pbs.sh
    echo "raxmlHPC -m GTRGAMMA -N 300 -p $RANDOM -n $UCE-bootGeneTree -s $UCE.phylip-relaxed -b $RANDOM                         ">>$UCE-raxml-pbs.sh
    echo "raxmlHPC -m GTRGAMMA -f b -t RAxML_bestTree.$UCE-bestGeneTree -z RAxML_bootstrap.$UCE-bootGeneTree -n bestBoot.tree   ">>$UCE-raxml-pbs.sh 
    echo "tar -cvzf runs-$UCE-bestGeneTree.tgz RAxML*bestGeneTree.RUN*                                                          ">>$UCE-raxml-pbs.sh 
    echo "tar -cvzf runs-$UCE-bootGeneTree.tgz RAxML*bootGeneTree.RUN*                                                          ">>$UCE-raxml-pbs.sh 
    echo "rm RAxML*RUN*                                                                                 ">>$UCE-raxml-pbs.sh

    cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning

    echo "cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/55pGeneTrees/$UCE"  >>qsub.sh
    echo "qsub $UCE-raxml-pbs.sh"                                                                       >>qsub.sh
    echo                                                                                                >>qsub.sh


done
###############################################################################################################################################################################
###############################################################################################################################################################################
###############################################################################################################################################################################
# bootstrapping binnedGene trees for astral bootstrapping



cp -r 50p_supergenes 50p_raxml_bootstrap

cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/50p_raxml_bootstrap

rm qsub-raxml-bootstrap.sh

for BIN_DIR in $(ls -d bin*.txt);
do

    cd $BIN_DIR

    BIN_NAME=$(basename $BIN_DIR .txt)

    echo $BIN_NAME   
s
    echo '#!/bin/bash                                                                                                           '>$BIN_NAME-raxml-pbs.sh
    echo "#$ -V                                                                                                                 ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -cwd                                                                                                               ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -S /bin/bash                                                                                                       ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -N $BIN_NAME                                                                                                        ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID                                                                                            ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -e \$JOB_NAME.e\$JOB_ID                                                                                            ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -q Chewie                                                                                                          ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -pe fill 1                                                                                                         ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -P communitycluster                                                                                                ">>$BIN_NAME-raxml-pbs.sh
    echo "                                                                                                                      ">>$BIN_NAME-raxml-pbs.sh
    echo "                                                                                                                      ">>$BIN_NAME-raxml-pbs.sh
    echo "raxmlHPC -m GTRGAMMA -N 150 -p $RANDOM -n $BIN_NAME.trees -s $BIN_NAME.fasta -q $BIN_NAME.part -b $RANDOM             ">>$BIN_NAME-raxml-pbs.sh


    cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/50p_raxml_bootstrap

    echo "cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/50p_raxml_bootstrap/$BIN_DIR"  >>qsub.sh
    echo "qsub $BIN_NAME-raxml-pbs.sh"                                                                          >>qsub.sh
    echo                                                                                                        >>qsub.sh


done





###############################################################################################################################################################################
###############################################################################################################################################################################
###############################################################################################################################################################################
###############################################################################################################################################################################


#PREPARING DATA FOR ASTRAL
#------------------------------------------------------------------------------------------------

#extract best tree from .tgz and weight
rm ./50p_bestGeneTrees_unweighted/50p_RAxML_unweighted.trees
rm ./50p_bestGeneTrees_weighted/50p_RAxML_weighted.trees
rm ./50p_bestGeneTrees_unweighted/unweighted_bootStrapGeneTrees.list
rm ./50p_bestGeneTrees_weighted/weighted_bootStrapGeneTrees.list

WORK_DIR=$(pwd)

for BINS in $(ls ./50p_pwise/*.txt); 
do 

    BASENAME_BIN=$(basename $BINS .txt)

    #get the tree
    tar -zvxf ./50p_raxml/$BASENAME_BIN.txt/$BASENAME_BIN-bestGeneTreeRAxML.tgz RAxML_bestTree.$BASENAME_BIN
    
    #create unweighted tree file and unweighte list of bootstrap replicates
    cat RAxML_bestTree.$BASENAME_BIN >>./50p_bestGeneTrees_unweighted/50p_RAxML_unweighted.trees
    echo $WORK_DIR/50p_raxml_bootstrap/$BASENAME_BIN.txt/RAxML_bootstrap.$BASENAME_BIN.trees >>./50p_bestGeneTrees_unweighted/unweighted_bootStrapGeneTrees.list


    WEIGHT=$(wc -l $BINS | cut -f1 -d" ")
    
    for I in $(seq 1 $WEIGHT)
    do
        #created weighted tree file and weighted list of bootstrap replicates      
        echo $WORK_DIR/50p_raxml_bootstrap/$BASENAME_BIN.txt/RAxML_bootstrap.$BASENAME_BIN.trees >>./50p_bestGeneTrees_weighted/weighted_bootStrapGeneTrees.list
        cat RAxML_bestTree.$BASENAME_BIN >>./50p_bestGeneTrees_weighted/50p_RAxML_weighted.trees
    done

    mv RAxML_bestTree.$BASENAME_BIN ./50p_raxml/$BASENAME_BIN.txt/

done

#!/bin/bash
#$ -V
#$ -cwd
#$ -S /bin/bash
#$ -N gtst-W
#$ -o $JOB_NAME.o$JOB_ID
#$ -e $JOB_NAME.e$JOB_ID
#$ -q Chewie,Yoda
#$ -pe fill 1
#$ -P communitycluster

java -jar /home/roplatt/bin/ASTRAL/astral.4.7.12.jar \
    -i 50p_RAxML_ueighted.trees \
    -o speciesTree_astral_weighted.tree \
    > astral.log 2>&1

java -jar /home/roplatt/bin/ASTRAL/astral.4.7.12.jar \
    -i 50p_RAxML_weighted.trees \
    -b weighted_bootStrapGeneTrees.list \
    -r 100 \
    -o siteResampling_astral_weighted.tree \
    > astral-r100.log 2>&1

java -jar /home/roplatt/bin/ASTRAL/astral.4.7.12.jar \
    -i 50p_RAxML_weighted.trees \
    -b weighted_bootStrapGeneTrees.list \
    -g \
    -r 100 \
    -o siteLocusResampling_astral_weighted.tree \
    > astral-gr100.log 2>&1


echo "$JOB_NAME finished" | mailx -s "$JOB_NAME finished" 9034521885@txt.att.net

#!/bin/bash
#$ -V
#$ -cwd
#$ -S /bin/bash
#$ -N gtst-U
#$ -o $JOB_NAME.o$JOB_ID
#$ -e $JOB_NAME.e$JOB_ID
#$ -q Chewie,Yoda
#$ -pe fill 1
#$ -P communitycluster

java -jar /home/roplatt/bin/ASTRAL/astral.4.7.12.jar \
    -i 50p_RAxML_unweighted.trees \
    -o speciesTree_astral_unweighted.tree \
    > astral.log 2>&1

java -jar /home/roplatt/bin/ASTRAL/astral.4.7.12.jar \
    -i 50p_RAxML_unweighted.trees \
    -b unweighted_bootStrapGeneTrees.list \
    -r 100 \
    -o siteResampling_astral_unweighted.tree \
    > astral-r100.log 2>&1

java -jar /home/roplatt/bin/ASTRAL/astral.4.7.12.jar \
    -i 50p_RAxML_unweighted.trees \
    -b unweighted_bootStrapGeneTrees.list \
    -g \
    -r 100 \
    -o siteLocusResampling_astral_unweighted.tree \
    > astral-gr100.log 2>&1


echo "$JOB_NAME finished" | mailx -s "$JOB_NAME finished" 9034521885@txt.att.net
