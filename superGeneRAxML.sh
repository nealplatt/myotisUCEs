cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/50p_raxml

rm qsub.sh


for BINNED_DIR in $(ls .); 
do 

    cd $BINNED_DIR

    BIN_NAME=$(basename $BINNED_DIR .txt)

    echo '#!/bin/bash                                                                                                   '>$BIN_NAME-raxml-pbs.sh
    echo "#$ -V                                                                                                         ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -cwd                                                                                                       ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -S /bin/bash                                                                                               ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -N $BIN_NAME                                                                                               ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID                                                                                    ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -e \$JOB_NAME.e\$JOB_ID                                                                                    ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -q Chewie                                                                                                  ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -pe fill 1                                                                                                 ">>$BIN_NAME-raxml-pbs.sh
    echo "#$ -P communitycluster                                                                                        ">>$BIN_NAME-raxml-pbs.sh
    echo "                                                                                                              ">>$BIN_NAME-raxml-pbs.sh
    echo "                                                                                                              ">>$BIN_NAME-raxml-pbs.sh
    echo "raxmlHPC -m GTRGAMMA -N 1000 -p $RANDOM -n $BIN_NAME -s $BIN_NAME.fasta -q $BIN_NAME.part                     ">>$BIN_NAME-raxml-pbs.sh
    echo "tar -cvzf $BIN_NAME-bestGeneTreeRAxML.tgz RAxML_*.bin.*                                                       ">>$BIN_NAME-raxml-pbs.sh 
    echo "rm RAxML_*.bin.*                                                                                              ">>$BIN_NAME-raxml-pbs.sh 

    cd ..

    echo "cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-binning/50p_raxml/$BINNED_DIR"              >>qsub.sh
    echo "qsub $BIN_NAME-raxml-pbs.sh"                                                                                  >>qsub.sh
    echo                                                                                                                >>qsub.sh

done
