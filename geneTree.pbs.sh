rm qsub.sh
rm -r /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-75p-complete-gtst/raxml/75pGeneTrees/*




for PHYLIP_FILE in $(ls /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-55p-complete-gtst/raxml/relaxedPhylip/*); 
do 

UCE=$(basename $PHYLIP_FILE .phylip-relaxed)


mkdir 75pGeneTrees/$UCE
cd 75pGeneTrees/$UCE

ln -s $PHYLIP_FILE

echo '#!/bin/bash                                                                           '>$UCE-raxml-pbs.sh
echo "#$ -V                                                                                 ">>$UCE-raxml-pbs.sh
echo "#$ -cwd                                                                               ">>$UCE-raxml-pbs.sh
echo "#$ -S /bin/bash                                                                       ">>$UCE-raxml-pbs.sh
echo "#$ -N $UCE                                                                            ">>$UCE-raxml-pbs.sh
echo "#$ -o \$JOB_NAME.o\$JOB_ID                                                            ">>$UCE-raxml-pbs.sh
echo "#$ -e \$JOB_NAME.e\$JOB_ID                                                            ">>$UCE-raxml-pbs.sh
echo "#$ -q Chewie                                                                          ">>$UCE-raxml-pbs.sh
echo "#$ -pe fill 1                                                                         ">>$UCE-raxml-pbs.sh
echo "#$ -P communitycluster                                                                ">>$UCE-raxml-pbs.sh
echo "                                                                                      ">>$UCE-raxml-pbs.sh
echo "                                                                                      ">>$UCE-raxml-pbs.sh
echo "raxmlHPC -m GTRGAMMA -N 100 -p $RANDOM -n $UCE-bestGeneTree -s $UCE.phylip-relaxed     ">>$UCE-raxml-pbs.sh



cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-75p-complete-gtst/raxml

echo "cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-75p-complete-gtst/raxml/75pGeneTrees/$UCE">>qsub.sh
echo "qsub $UCE-raxml-pbs.sh"                                                                        >>qsub.sh
echo                                                                                                 >>qsub.sh


done

