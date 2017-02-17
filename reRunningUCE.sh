#rsync -rltuvP --delete roplatt@hrothgar.hpcc.ttu.edu:~/myotisUCEs/neal/ /home/neal/Dropbox/myotisUCEs/neal


WORK_DIR=/home/roplatt/myotisUCEs/neal/play
PROCESSORS=10
BAYES_PROCESSORS=16
RAXML_PROCESSORS=10

cd $WORK_DIR

#############################
#make config file for exabayes

echo "#NEXUS"                   >$WORK_DIR/bin/1M-4C-4R_config.nex
echo ""                         >>$WORK_DIR/bin/1M-4C-4R_config.nex
echo "begin run;"               >>$WORK_DIR/bin/1M-4C-4R_config.nex
echo " numruns 4"               >>$WORK_DIR/bin/1M-4C-4R_config.nex
echo " numCoupledChains 4"      >>$WORK_DIR/bin/1M-4C-4R_config.nex
echo " numGen 1000000"          >>$WORK_DIR/bin/1M-4C-4R_config.nex
echo " sdsfConvergence 0.01"    >>$WORK_DIR/bin/1M-4C-4R_config.nex
echo " burninProportion 0.25"   >>$WORK_DIR/bin/1M-4C-4R_config.nex
echo "end;"                     >>$WORK_DIR/bin/1M-4C-4R_config.nex

#-----------------------------------------------------




#use a for loop to extract UCE loci with 
for i in 15 25 35 45 55 65 75 85 95 100
do
    PERCENT=$(printf '%.2f\n' "$(bc <<< "scale=2; $i/100")")

    #sort alignments based on a min number of taxa
    phyluce_align_get_only_loci_with_min_taxa \
        --alignments $WORK_DIR/mafft-gblocks-clean/ \
        --cores $PROCESSORS \
        --taxa 37 \
        --output $WORK_DIR/$i"_alignments" \
        --percent $PERCENT    

    #combine those alignments into a single concatenated file
    phyluce_align_format_nexus_files_for_raxml \
        --alignments $WORK_DIR/$i"_alignments" \
        --output $WORK_DIR/$i"_FP_raxml" \
        --charsets
    
    #convert concatenated nexus file partitions into format available to RAxML and exaBayes
    perl bin/raxml_nexusPartConvert.pl -m "$i"_FP_raxml/"$i"_alignments.charsets -r DNA >"$i"_FP_raxml/"$i".partitions

    
    #copy data from FP raxml to UP and OP raxml dirs
    cp -r $WORK_DIR/$i"_FP_raxml" $WORK_DIR/$i"_UP_raxml"
    cp -r $WORK_DIR/$i"_FP_raxml" $WORK_DIR/$i"_OP_raxml"

    #remove the parition data from unpartitioned analysis directories
    rm $WORK_DIR/*UP*/*.partitions $WORK_DIR/*UP*/*.charsets

    #copy RAxML directories into unique exabayes directories
    cp -r $WORK_DIR/$i"_FP_raxml" $WORK_DIR/$i"_FP_exabayes"
    cp -r $WORK_DIR/$i"_UP_raxml" $WORK_DIR/$i"_UP_exabayes"
    cp -r $WORK_DIR/$i"_OP_raxml" $WORK_DIR/$i"_OP_exabayes"    



done


#setup raxml runs
#unpartitioned
for i in 15 25 35 45 55 65 75 85 95 100
do


cd $WORK_DIR/"$i"_UP_raxml

    rm "$i"_UP_raxml.pbs.sh

    echo '#!/bin/bash' >>"$i"_UP_raxml.pbs.sh
    echo "#$ -V" >>"$i"_UP_raxml.pbs.sh
    echo "#$ -cwd" >>"$i"_UP_raxml.pbs.sh
    echo "#$ -S /bin/bash" >>"$i"_UP_raxml.pbs.sh
    echo "#$ -N ml-"$i"-UP" >>"$i"_UP_raxml.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID" >>"$i"_UP_raxml.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID" >>"$i"_UP_raxml.pbs.sh
    echo "#$ -q Chewie,Yoda,R2D2" >>"$i"_UP_raxml.pbs.sh
    echo "#$ -pe fill $RAXML_PROCESSORS" >>"$i"_UP_raxml.pbs.sh
    echo "#$ -P communitycluster" >>"$i"_UP_raxml.pbs.sh
    echo "" >>"$i"_UP_raxml.pbs.sh
    echo "#run RAxML and find best tree from 100 searches" >>"$i"_UP_raxml.pbs.sh
    echo "mpirun -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p "$RANDOM" -n "$i"_UP-best -s "$i"_alignments.phylip" >>"$i"_UP_raxml.pbs.sh
    echo "" >>"$i"_UP_raxml.pbs.sh
    echo "#run RAxML and bootstrap 1K times" >>"$i"_UP_raxml.pbs.sh
    echo "mpirun -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 1000 -p $RANDOM -b $RANDOM -n "$i"_UP-bootreps -s "$i"_alignments.phylip" >>"$i"_UP_raxml.pbs.sh
    echo "" >>"$i"_UP_raxml.pbs.sh
    echo "#run RAxML and add bootstrap bipartition frequencies to best tree" >>"$i"_UP_raxml.pbs.sh
    echo "raxmlHPC -m GTRGAMMA -f b -t RAxML_bestTree."$i"_UP-best -z RAxML_bootstrap."$i"_UP-bootreps" >>"$i"_UP_raxml.pbs.sh
    echo "" >>"$i"_UP_raxml.pbs.sh
    echo "#run RAxML and test for boostrap convergence" >>"$i"_UP_raxml.pbs.sh
    echo "raxmlHPC -m GTRGAMMA -z RAxML_bootstrap."$i"_UP-bootreps -I autoMRE -p $RANDOM -n converge" >>"$i"_UP_raxml.pbs.sh

    cd $WORK_DIR
    echo "cd $WORK_DIR/"$i"_UP_raxml; qsub "$i"_UP_raxml.pbs.sh; cd $WORK_DIR" >>qsub_UP_RAxML.sh

done



for i in 15 25 35 45 55 65 75 85 95 100
 do

    cd $WORK_DIR/"$i"_FP_raxml
    rm "$i"_FP_raxml.pbs.sh
     
    echo '#!/bin/bash' >>"$i"_FP_raxml.pbs.sh
     echo "#$ -V" >>"$i"_FP_raxml.pbs.sh
     echo "#$ -cwd" >>"$i"_FP_raxml.pbs.sh
     echo "#$ -S /bin/bash" >>"$i"_FP_raxml.pbs.sh
     echo "#$ -N ml-"$i"-FP" >>"$i"_FP_raxml.pbs.sh
     echo "#$ -o \$JOB_NAME.o\$JOB_ID" >>"$i"_FP_raxml.pbs.sh   
     echo "#$ -e \$JOB_NAME.e\$JOB_ID" >>"$i"_FP_raxml.pbs.sh
     echo "#$ -q Chewie,Yoda,R2D2" >>"$i"_FP_raxml.pbs.sh
     echo "#$ -pe fill $RAXML_PROCESSORS" >>"$i"_FP_raxml.pbs.sh
     echo "#$ -P communitycluster" >>"$i"_FP_raxml.pbs.sh
     echo "" >>"$i"_FP_raxml.pbs.sh
     echo "#run RAxML and find best tree from 100 searches" >>"$i"_FP_raxml.pbs.sh
     echo "mpirun -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p "$RANDOM" -n "$i"_FP-best -s "$i"_alignments.phylip -q "$i".partitions" >>"$i"_FP_raxml.pbs.sh
     echo "" >>"$i"_FP_raxml.pbs.sh
     echo "#run RAxML and bootstrap 1K times" >>"$i"_FP_raxml.pbs.sh
     echo "mpirun -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 1000 -p $RANDOM -b $RANDOM -n "$i"_FP-bootreps -s "$i"_alignments.phylip -q "$i".partitions" >>"$i"_FP_raxml.pbs.sh
     echo "" >>"$i"_FP_raxml.pbs.sh
     echo "#run RAxML and add bootstrap bipartition frequencies to best tree" >>"$i"_FP_raxml.pbs.sh
     echo "raxmlHPC -m GTRGAMMA -f b -t RAxML_bestTree."$i"_FP-best -z RAxML_bootstrap."$i"_FP-bootreps" >>"$i"_FP_raxml.pbs.sh
     echo "" >>"$i"_FP_raxml.pbs.sh
     echo "#run RAxML and test for boostrap convergence" >>"$i"_FP_raxml.pbs.sh
     echo "raxmlHPC -m GTRGAMMA -z RAxML_bootstrap."$i"_FP-bootreps -I autoMRE -p $RANDOM -n converge" >>"$i"_FP_raxml.pbs.sh
      cd $WORK_DIR/
     echo "cd $WORK_DIR/"$i"_FP_raxml;  qsub "$i"_FP_raxml.pbs.sh;  cd $WORK_DIR" >>qsub_FP_RAxML.sh
  done


for i in 15 25 35 45 55 65 75 85 95 100
  do

    cd $WORK_DIR/"$i"_FP_exabayes
    rm "$i"_FP_exabayes.pbs.sh

    cp $WORK_DIR/bin/1M-4C-4R_config.nex .

    echo '#!/bin/bash' >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -V" >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -cwd" >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -S /bin/bash" >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -N ml-"$i"-FP" >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID" >>"$i"_FP_exabayes.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID" >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -q Chewie,Yoda,R2D2" >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -pe fill $BAYES_PROCESSORS" >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -P communitycluster" >>"$i"_FP_exabayes.pbs.sh
    echo "" >>"$i"_FP_exabayes.pbs.sh
    echo "mpirun -np $BAYES_PROCESSORS exabayes -m DNA -C 4 -R 4 -s $RANDOM -c 1M-4C-4R_config.nex -f "$i"_alignments.phylip -n 1M-4C-4R-"$i"-FP -q "$i".partitions" >>"$i"_FP_exabayes.pbs.sh
    echo "" >>"$i"_FP_exabayes.pbs.sh
    echo "consense -f ExaBayes_topologies.1M-4C-4R-"$i"-FP.* -n "$i"-FP_myCons" >>"$i"_FP_exabayes.pbs.sh
    echo "" >>"$i"_FP_exabayes.pbs.sh
    echo "postProcParam -f ExaBayes_parameters.1M-4C-4R-"$i"-FP.* -n "$i"-FP_params" >>"$i"_FP_exabayes.pbs.sh
    echo "" >>"$i"_FP_exabayes.pbs.sh
    echo "extractBips -f ExaBayes_topologies.1M-4C-4R-"$i"-FP.* -n "$i"-FP_bls" >>"$i"_FP_exabayes.pbs.sh

    cd $WORK_DIR/
    echo "cd $WORK_DIR/"$i"_FP_exabayes;  qsub "$i"_FP_exabayes.pbs.sh;  cd .." >>qsub_FP_exabayes.sh
 
 done


for i in 15 25 35 45 55 65 75 85 95 100
  do

    cd $WORK_DIR/"$i"_UP_exabayes
    rm "$i"_UP_exabayes.pbs.sh

    cp $WORK_DIR/bin/1M-4C-4R_config.nex .

    echo '#!/bin/bash' >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -V" >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -cwd" >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -S /bin/bash" >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -N ml-"$i"-FP" >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID" >>"$i"_UP_exabayes.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID" >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -q Chewie,Yoda,R2D2" >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -pe fill $BAYES_PROCESSORS" >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -P communitycluster" >>"$i"_UP_exabayes.pbs.sh
    echo "" >>"$i"_UP_exabayes.pbs.sh
    echo "mpirun -np $BAYES_PROCESSORS exabayes -m DNA -C 4 -R 4 -s $RANDOM -c 1M-4C-4R_config.nex -f "$i"_alignments.phylip -n 1M-4C-4R-"$i"-FP" >>"$i"_UP_exabayes.pbs.sh
    echo "" >>"$i"_UP_exabayes.pbs.sh
    echo "consense -f ExaBayes_topologies.1M-4C-4R-"$i"-FP.* -n "$i"-FP_myCons" >>"$i"_UP_exabayes.pbs.sh
    echo "" >>"$i"_UP_exabayes.pbs.sh
    echo "postProcParam -f ExaBayes_parameters.1M-4C-4R-"$i"-FP.* -n "$i"-FP_params" >>"$i"_UP_exabayes.pbs.sh
    echo "" >>"$i"_UP_exabayes.pbs.sh
    echo "extractBips -f ExaBayes_topologies.1M-4C-4R-"$i"-FP.* -n "$i"-FP_bls" >>"$i"_UP_exabayes.pbs.sh

    cd $WORK_DIR
    echo "cd $WORK_DIR/"$i"_UP_exabayes;  qsub "$i"_UP_exabayes.pbs.sh;  cd $WORK_DIR" >>qsub_UP_exabayes.sh
 
 done




#now need to figure out how to run partition finder on the cluster and run each analysis on OP (optimum partitions)



for i in 15 25 35 45 55 65 75 85 95 100
  do

    cp -r $WORK_DIR/$i"_FP_raxml" $WORK_DIR/$i"_OP_raxml"
    
    cd $WORK_DIR/$i"_OP_raxml"
    rm $i"_OP_raxml".pbs.sh
    rm $i"_FP_raxml".pbs.sh


    echo "# ALIGNMENT FILE #" >partition_finder.cfg
    echo "alignment = "$i"_alignments.phylip;" >>partition_finder.cfg
    echo "" >>partition_finder.cfg
    echo "# BRANCHLENGTHS #" >>partition_finder.cfg
    echo "branchlengths = linked;" >>partition_finder.cfg
    echo "" >>partition_finder.cfg
    echo "# MODELS OF EVOLUTION #" >>partition_finder.cfg
    echo "models = GTR+G;" >>partition_finder.cfg
    echo "model_selection = bic;" >>partition_finder.cfg
    echo "" >>partition_finder.cfg
    echo "# DATA BLOCKS #" >>partition_finder.cfg
    echo "[data_blocks]" >>partition_finder.cfg
    cat $i.partitions | sed "s/DNA, //" | sed "s/'//g" | sed 's/$/;/' | sed 's/.nexus//' >>partition_finder.cfg
    echo "" >>partition_finder.cfg
    echo "# SCHEMES #" >>partition_finder.cfg
    echo "[schemes]" >>partition_finder.cfg
    echo "search = rcluster;" >>partition_finder.cfg
    echo "" >>partition_finder.cfg



     echo '#!/bin/bash' >>"$i"_OP_raxml.pbs.sh
     echo "#$ -V" >>"$i"_OP_raxml.pbs.sh
     echo "#$ -cwd" >>"$i"_OP_raxml.pbs.sh
     echo "#$ -S /bin/bash" >>"$i"_OP_raxml.pbs.sh
     echo "#$ -N ml-"$i"-OP" >>"$i"_OP_raxml.pbs.sh
     echo "#$ -o \$JOB_NAME.o\$JOB_ID" >>"$i"_OP_raxml.pbs.sh   
     echo "#$ -e \$JOB_NAME.e\$JOB_ID" >>"$i"_OP_raxml.pbs.sh
     echo "#$ -q Chewie,Yoda,R2D2" >>"$i"_OP_raxml.pbs.sh
     echo "#$ -pe fill $RAXML_PROCESSORS" >>"$i"_OP_raxml.pbs.sh
     echo "#$ -P communitycluster" >>"$i"_OP_raxml.pbs.sh
     echo "" >>"$i"_OP_raxml.pbs.sh
     echo "python ../bin/PartitionFinderV1.1.1_Mac/PartitionFinder . -p $RAXML_PROCESSORS --raxml --rcluster-percent 1" >>"$i"_OP_raxml.pbs.sh
     echo "cat ./analysis/best_scheme.txt | grep \"DNA, p\" >"$i"_OP.partitions" >>"$i"_OP_raxml.pbs.sh
     echo "" >>"$i"_OP_raxml.pbs.sh
     echo "#run RAxML and find best tree from 100 searches" >>"$i"_OP_raxml.pbs.sh
     echo "mpirun -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p "$RANDOM" -n "$i"_OP-best -s "$i"_alignments.phylip -q "$i"_OP.partitions" >>"$i"_OP_raxml.pbs.sh
     echo "" >>"$i"_OP_raxml.pbs.sh
     echo "#run RAxML and bootstrap 1K times" >>"$i"_OP_raxml.pbs.sh
     echo "mpirun -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 1000 -p $RANDOM -b $RANDOM -n "$i"_OP-bootreps -s "$i"_alignments.phylip -q "$i"_OP.partitions" >>"$i"_OP_raxml.pbs.sh
     echo "" >>"$i"_OP_raxml.pbs.sh
     echo "#run RAxML and add bootstrap bipartition frequencies to best tree" >>"$i"_OP_raxml.pbs.sh
     echo "raxmlHPC -m GTRGAMMA -f b -t RAxML_bestTree."$i"_OP-best -z RAxML_bootstrap."$i"_OP-bootreps" >>"$i"_OP_raxml.pbs.sh
     echo "" >>"$i"_OP_raxml.pbs.sh
     echo "#run RAxML and test for boostrap convergence" >>"$i"_OP_raxml.pbs.sh
     echo "raxmlHPC -m GTRGAMMA -z RAxML_bootstrap."$i"_OP-bootreps -I autoMRE -p $RANDOM -n converge" >>"$i"_OP_raxml.pbs.sh
     
     cd $WORK_DIR/
     echo "cd $WORK_DIR/"$i"_OP_raxml;  qsub "$i"_OP_raxml.pbs.sh;  cd $WORK_DIR" >>qsub_OP_raxml.sh


     cp -r $WORK_DIR/$i"_OP_raxml" $WORK_DIR/$i"_OP_exabayes"

    cd $WORK_DIR/$i"_OP_exabayes"
    rm *raxml* partition_finder.cfg

    cp $WORK_DIR/bin/1M-4C-4R_config.nex .

    echo '#!/bin/bash' >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -V" >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -cwd" >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -S /bin/bash" >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -N xB-"$i"-OP" >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID" >>"$i"_OP_exabayes.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID" >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -q Chewie,Yoda,R2D2" >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -pe fill $BAYES_PROCESSORS" >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -P communitycluster" >>"$i"_OP_exabayes.pbs.sh
    echo "" >>"$i"_OP_exabayes.pbs.sh
    echo "cp ../"$i"_OP_raxml/"$i"_OP.partitions ." >>"$i"_OP_exabayes.pbs.sh
    echo "mpirun -np $BAYES_PROCESSORS exabayes -m DNA -C 4 -R 4 -s $RANDOM -c 1M-4C-4R_config.nex -f "$i"_alignments.phylip -n 1M-4C-4R-"$i"-OP -q "$i"_OP.partitions">>"$i"_OP_exabayes.pbs.sh
    echo "" >>"$i"_OP_exabayes.pbs.sh
    echo "consense -f ExaBayes_topologies.1M-4C-4R-"$i"-FP.* -n "$i"-OP_myCons" >>"$i"_OP_exabayes.pbs.sh
    echo "" >>"$i"_OP_exabayes.pbs.sh
    echo "postProcParam -f ExaBayes_parameters.1M-4C-4R-"$i"-OP.* -n "$i"-OP_params" >>"$i"_OP_exabayes.pbs.sh
    echo "" >>"$i"_OP_exabayes.pbs.sh
    echo "extractBips -f ExaBayes_topologies.1M-4C-4R-"$i"-OP.* -n "$i"-OP_bls" >>"$i"_OP_exabayes.pbs.sh

    cd $WORK_DIR
    echo "cd $WORK_DIR/"$i"_OP_exabayes;  qsub "$i"_OP_exabayes.pbs.sh;  cd $WORK_DIR" >>qsub_OP_exabayes.sh

 done



chmod u+x qsub_FP_exabayes.sh  qsub_FP_RAxML.sh  qsub_UP_RAxML.sh  qsub_UP_exabayes.sh qsub_OP_exabayes.sh qsub_OP_raxml.sh












