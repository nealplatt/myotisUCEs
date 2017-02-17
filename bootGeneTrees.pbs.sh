rm qsub-boot.sh
rm -r /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-75p-complete-gtst/raxml/75pBootGeneTrees/*

for PHYLIP_FILE in $(ls /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-75p-complete-gtst/raxml/relaxedPhylip/*); 
do 

UCE=$(basename $PHYLIP_FILE .phylip-relaxed)


mkdir 75pBootGeneTrees/$UCE
cd 75pBootGeneTrees/$UCE

ln -s $PHYLIP_FILE

echo '#!/bin/bash                                                                                           '>$UCE-bootRaxml-pbs.sh
echo "#$ -V                                                                                                 ">>$UCE-bootRaxml-pbs.sh
echo "#$ -cwd                                                                                               ">>$UCE-bootRaxml-pbs.sh
echo "#$ -S /bin/bash                                                                                       ">>$UCE-bootRaxml-pbs.sh
echo "#$ -N $UCE                                                                                            ">>$UCE-bootRaxml-pbs.sh
echo "#$ -o \$JOB_NAME.o\$JOB_ID                                                                            ">>$UCE-bootRaxml-pbs.sh
echo "#$ -e \$JOB_NAME.e\$JOB_ID                                                                            ">>$UCE-bootRaxml-pbs.sh
echo "#$ -q Chewie,Yoda                                                                                     ">>$UCE-bootRaxml-pbs.sh
echo "#$ -pe fill 1                                                                                         ">>$UCE-bootRaxml-pbs.sh
echo "#$ -P communitycluster                                                                                ">>$UCE-bootRaxml-pbs.sh
echo "                                                                                                      ">>$UCE-bootRaxml-pbs.sh
echo "                                                                                                      ">>$UCE-bootRaxml-pbs.sh
echo "raxmlHPC -m GTRGAMMA -N 500 -p $RANDOM -b $RANDOM -n $UCE-bootstrapGeneTree -s $UCE.phylip-relaxed    ">>$UCE-bootRaxml-pbs.sh



 cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-75p-complete-gtst/raxml

echo "cd /home/roplatt/myotisUCEs/neal/mafft-gblocks-clean-75p-complete-gtst/raxml/75pBootGeneTrees/$UCE"   >>qsub-boot.sh
echo "qsub $UCE-bootRaxml-pbs.sh"                                                                           >>qsub-boot.sh
echo                                                                                                        >>qsub-boot.sh


done

