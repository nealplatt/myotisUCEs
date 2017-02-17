#rsync -rltuvP --delete roplatt@hrothgar.hpcc.ttu.edu:~/myotisUCEs/neal/ /home/neal/Dropbox/myotisUCEs/neal


WORK_DIR=/home/roplatt/myotisUCEs/neal/play
PROCESSORS=10
BAYES_PROCESSORS=16
RAXML_PROCESSORS=10
QUEUE=Chewie

cd $WORK_DIR


#There are a few names that need to be fixed in the alignments.
#something needs to be added here to switch the taka that are messed up.  velifer and levis?, fix to m. ater and septentrionalis
#myotis_atacamensis_M4430 is myotis_ater_M4430
#myotis_austroriparius_RDS7705 is myotis_septentrionalis_RDS7705
#myotis_velifer_MSB70877 and myotis_levsi_RDS7781 need to be switched.

#cp -r originalAlignments/ modifiedAlignments/
#cd modifiedAlignments

##change names here
#sed -i 's/myotis_atacamensis_M4430/myotis_ater_M4430/gi' *.nexus
#sed -i 's/myotis_austroriparius_RDS7705/myotis_septentrionalis_RDS7705/gi' *.nexus

##need to be switched.  not sure how to do it at once so give each a intermediate name
#sed -i 's/myotis_velifer_MSB70877/tmplevis/gi' *.nexus
#sed -i 's/myotis_levis_RDS7781/tmpvelifer/gi' *.nexus

##then change intermediate names to final names
#sed -i 's/tmplevis/myotis_levis_RDS7781/gi' *.nexus
#sed -i 's/tmpvelifer/myotis_velifer_MSB70877/gi' *.nexus


cd $WORK_DIR
#############################
#make config file for exabayes

echo "#NEXUS"                   >$WORK_DIR/bin/100K-4C-4R_config.nex
echo ""                         >>$WORK_DIR/bin/100K-4C-4R_config.nex
echo "begin run;"               >>$WORK_DIR/bin/100K-4C-4R_config.nex
echo " numruns 4"               >>$WORK_DIR/bin/100K-4C-4R_config.nex
echo " numCoupledChains 4"      >>$WORK_DIR/bin/100K-4C-4R_config.nex
echo " numGen 100000"           >>$WORK_DIR/bin/100K-4C-4R_config.nex
echo " sdsfConvergence 0.01"    >>$WORK_DIR/bin/100K-4C-4R_config.nex
echo " burninProportion 0.25"   >>$WORK_DIR/bin/100K-4C-4R_config.nex
echo "end;"                     >>$WORK_DIR/bin/100K-4C-4R_config.nex

#-----------------------------------------------------



cd $WORK_DIR
#use a for loop to extract UCE loci with 
for i in 15 25 35 45 55 65 75 85 95 100
do
    PERCENT=$(printf '%.2f\n' "$(bc <<< "scale=2; $i/100")")

    #sort alignments based on a min number of taxa
    phyluce_align_get_only_loci_with_min_taxa \
        --alignments $WORK_DIR/modifiedAlignments/ \
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


#Once all of the lignment files are created, then we use a for loop to create six different analyses pers set of alignments
#  1) RAxML      No_par     100 bootreps      
#  2) RAxML      Full_par   100 bootreps
#  3) RAxML      Opt_par    100 bootreps
#  4) exaBayes   No_par     100K gen
#  5) exaBayes   Full_par   100K gen
#  6) exaBayes   Opt_par    100K gen
#
# For each analyses a qsub file is created so all jobs can be submitted at once


for i in 15 25 35 45 55 65 75 85 95 100
do

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#  [1] R A x M L    N O    P A R T I T I O N
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #move into the UP_raxml directory
    cd $WORK_DIR/"$i"_UP_raxml

    #if a submission file exits...delete it
    if [ -f "$i"_UP_raxml.pbs.sh ]
        then
        rm "$i"_UP_raxml.pbs.sh
    fi
    
    #create a qsub file to run a full RAxML run 
    echo '#!/bin/bash'                                                                                                                                          >>"$i"_UP_raxml.pbs.sh
    echo "#$ -V"                                                                                                                                                >>"$i"_UP_raxml.pbs.sh
    echo "#$ -cwd"                                                                                                                                              >>"$i"_UP_raxml.pbs.sh
    echo "#$ -S /bin/bash"                                                                                                                                      >>"$i"_UP_raxml.pbs.sh
    echo "#$ -N ml-"$i"-UP"                                                                                                                                     >>"$i"_UP_raxml.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID"                                                                                                                           >>"$i"_UP_raxml.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID"                                                                                                                           >>"$i"_UP_raxml.pbs.sh
    echo "#$ -q $QUEUE"                                                                                                                                         >>"$i"_UP_raxml.pbs.sh
    echo "#$ -pe fill $RAXML_PROCESSORS"                                                                                                                        >>"$i"_UP_raxml.pbs.sh
    echo "#$ -P communitycluster"                                                                                                                               >>"$i"_UP_raxml.pbs.sh
    echo ""                                                                                                                                                     >>"$i"_UP_raxml.pbs.sh
    echo "#run RAxML and find best tree from 100 searches"                                                                                                      >>"$i"_UP_raxml.pbs.sh
    echo "mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p "$RANDOM" -n "$i"_UP-best -s "$i"_alignments.phylip"                   >>"$i"_UP_raxml.pbs.sh
    echo ""                                                                                                                                                     >>"$i"_UP_raxml.pbs.sh
    echo "#run RAxML and bootstrap 100 times"                                                                                                                   >>"$i"_UP_raxml.pbs.sh
    echo "mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p $RANDOM -b $RANDOM -n "$i"_UP-bootreps -s "$i"_alignments.phylip"      >>"$i"_UP_raxml.pbs.sh
    echo ""                                                                                                                                                     >>"$i"_UP_raxml.pbs.sh
    echo "#run RAxML and add bootstrap bipartition frequencies to best tree"                                                                                    >>"$i"_UP_raxml.pbs.sh
    echo "raxmlHPC -m GTRGAMMA -f b -t RAxML_bestTree."$i"_UP-best -z RAxML_bootstrap."$i"_UP-bootreps"                                                         >>"$i"_UP_raxml.pbs.sh
    echo ""                                                                                                                                                     >>"$i"_UP_raxml.pbs.sh
    echo "#run RAxML and test for boostrap convergence"                                                                                                         >>"$i"_UP_raxml.pbs.sh
    echo "raxmlHPC -m GTRGAMMA -z RAxML_bootstrap."$i"_UP-bootreps -I autoMRE -p $RANDOM -n converge"                                                           >>"$i"_UP_raxml.pbs.sh

    cd $WORK_DIR

    #create file in the working directory that will recursivley submit all *_UP_RAxML jobs at once.
    echo "cd $WORK_DIR/"$i"_UP_raxml; qsub "$i"_UP_raxml.pbs.sh; cd $WORK_DIR" >>qsub_UP_raxml.sh

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#  [2] R A x M L    F U L L    P A R T I T I O N
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #move into the FP_raxml directory (Fully partitioned)
    cd $WORK_DIR/"$i"_FP_raxml

    #if a submission file exits...delete it
    if [ -f "$i"_FP_raxml.pbs.sh ]
        then
        rm "$i"_FP_raxml.pbs.sh
    fi

    #create a qsub file to run a full RAxML run on the fully partitioned data 
    echo '#!/bin/bash'                                                                                                                                                              >>"$i"_FP_raxml.pbs.sh
    echo "#$ -V"                                                                                                                                                                    >>"$i"_FP_raxml.pbs.sh
    echo "#$ -cwd"                                                                                                                                                                  >>"$i"_FP_raxml.pbs.sh
    echo "#$ -S /bin/bash"                                                                                                                                                          >>"$i"_FP_raxml.pbs.sh
    echo "#$ -N ml-"$i"-FP"                                                                                                                                                         >>"$i"_FP_raxml.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID"                                                                                                                                               >>"$i"_FP_raxml.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID"                                                                                                                                               >>"$i"_FP_raxml.pbs.sh
    echo "#$ -q $QUEUE"                                                                                                                                                             >>"$i"_FP_raxml.pbs.sh
    echo "#$ -pe fill $RAXML_PROCESSORS"                                                                                                                                            >>"$i"_FP_raxml.pbs.sh
    echo "#$ -P communitycluster"                                                                                                                                                   >>"$i"_FP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_FP_raxml.pbs.sh
    echo "#run RAxML and find best tree from 100 searches"                                                                                                                          >>"$i"_FP_raxml.pbs.sh
    echo "mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p "$RANDOM" -n "$i"_FP-best -s "$i"_alignments.phylip -q "$i".partitions"                    >>"$i"_FP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_FP_raxml.pbs.sh
    echo "#run RAxML and bootstrap 100 times"                                                                                                                                        >>"$i"_FP_raxml.pbs.sh
    echo "mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p $RANDOM -b $RANDOM -n "$i"_FP-bootreps -s "$i"_alignments.phylip -q "$i".partitions"       >>"$i"_FP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_FP_raxml.pbs.sh
    echo "#run RAxML and add bootstrap bipartition frequencies to best tree"                                                                                                        >>"$i"_FP_raxml.pbs.sh
    echo "raxmlHPC -m GTRGAMMA -f b -t RAxML_bestTree."$i"_FP-best -z RAxML_bootstrap."$i"_FP-bootreps"                                                                             >>"$i"_FP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_FP_raxml.pbs.sh
    echo "#run RAxML and test for boostrap convergence"                                                                                                                             >>"$i"_FP_raxml.pbs.sh
    echo "raxmlHPC -m GTRGAMMA -z RAxML_bootstrap."$i"_FP-bootreps -I autoMRE -p $RANDOM -n converge"                                                                               >>"$i"_FP_raxml.pbs.sh
  
    cd $WORK_DIR

    #create file in the working directory that will recursivley submit all *_UP_RAxML jobs at once.
    echo "cd $WORK_DIR/"$i"_FP_raxml;  qsub "$i"_FP_raxml.pbs.sh;  cd $WORK_DIR" >>qsub_FP_raxml.sh

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#  [3] R A x M L    O P T I M U M    P A R T I T I O N
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #move into the OP_raxml directory (optimum partitioned)
    cd $WORK_DIR/$i"_OP_raxml"

        #to run the "optimum" partitions I use partitions finder.  It has been placed in $WORK_DIR/bin/PartitionFinderV1.1.1_Mac/PartitionFinder
    #  PartitionFinder needs a config file named "partition_finder.cfg".  The thing to be aware of here is that the partitions file
    #  created for raxml will serve as "raw" input into the # DATA BLOCKS # section of the config file.  It is modified on the fly
    #  and incorporated into the config file below.

    #if a pfinder config file exits...delete it
    if [ -f partition_finder.cfg ]
        then
        rm partition_finder.cfg
    fi


    echo "# ALIGNMENT FILE #"                                                               >>partition_finder.cfg
    echo "alignment = "$i"_alignments.phylip;"                                              >>partition_finder.cfg
    echo ""                                                                                 >>partition_finder.cfg
    echo "# BRANCHLENGTHS #"                                                                >>partition_finder.cfg
    echo "branchlengths = linked;"                                                          >>partition_finder.cfg
    echo ""                                                                                 >>partition_finder.cfg
    echo "# MODELS OF EVOLUTION #"                                                          >>partition_finder.cfg
    echo "models = GTR+G;"                                                                  >>partition_finder.cfg
    echo "model_selection = bic;"                                                           >>partition_finder.cfg
    echo ""                                                                                 >>partition_finder.cfg
    echo "# DATA BLOCKS #"                                                                  >>partition_finder.cfg
    echo "[data_blocks]"                                                                    >>partition_finder.cfg
    cat $i.partitions | sed "s/DNA, //" | sed "s/'//g" | sed 's/$/;/' | sed 's/.nexus//'    >>partition_finder.cfg
    echo ""                                                                                 >>partition_finder.cfg
    echo "# SCHEMES #"                                                                      >>partition_finder.cfg
    echo "[schemes]"                                                                        >>partition_finder.cfg
    echo "search = hcluster;"                                                               >>partition_finder.cfg
    echo ""                                                                                 >>partition_finder.cfg

    #if a optimum partition qsub file exists...delete it
    if [ -f "$i"_OP_raxml.pbs.sh ]
        then
        rm "$i"_OP_raxml.pbs.sh
    fi

    #so this is kind of weird but makes things work down the line...
    #  create an empty file that is a standin for the optimum partitions.  Once partition finder runs (qsub)
    #  the data will then be copied into this file.  The resason it is created here (and now) is so that it can
    #  be linked to for the exabayes fun down the line.
    touch "$i"_OP.partitions


    #once the config file has been generated a qsub script is generated that contains an additional step from the ones above
    #  it will run partition finder, then take those results and modify them in a way that they can be used as "-q" partitions
    #  by RAxML
    echo '#!/bin/bash'                                                                                                                                                              >>"$i"_OP_raxml.pbs.sh
    echo "#$ -V"                                                                                                                                                                    >>"$i"_OP_raxml.pbs.sh
    echo "#$ -cwd"                                                                                                                                                                  >>"$i"_OP_raxml.pbs.sh
    echo "#$ -S /bin/bash"                                                                                                                                                          >>"$i"_OP_raxml.pbs.sh
    echo "#$ -N ml-"$i"-OP"                                                                                                                                                         >>"$i"_OP_raxml.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID"                                                                                                                                               >>"$i"_OP_raxml.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID"                                                                                                                                               >>"$i"_OP_raxml.pbs.sh
    echo "#$ -q $QUEUE"                                                                                                                                                             >>"$i"_OP_raxml.pbs.sh
    echo "#$ -pe sm $RAXML_PROCESSORS"                                                                                                                                            >>"$i"_OP_raxml.pbs.sh
    echo "#$ -P communitycluster"                                                                                                                                                   >>"$i"_OP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_OP_raxml.pbs.sh
    echo "python ../bin/PartitionFinderV1.1.1_Mac/PartitionFinder.py . -p $RAXML_PROCESSORS --raxml"                                                           >>"$i"_OP_raxml.pbs.sh
    echo "cat ./analysis/best_scheme.txt | grep \"DNA, p\" >>"$i"_OP.partitions"                                                                                                    >>"$i"_OP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_OP_raxml.pbs.sh
    echo "#run RAxML and find best tree from 100 searches"                                                                                                                          >>"$i"_OP_raxml.pbs.sh
    echo "mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p "$RANDOM" -n "$i"_OP-best -s "$i"_alignments.phylip -q "$i"_OP.partitions"                 >>"$i"_OP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_OP_raxml.pbs.sh
    echo "#run RAxML and bootstrap 100 times"                                                                                                                                       >>"$i"_OP_raxml.pbs.sh
    echo "mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -m GTRGAMMA -N 100 -p $RANDOM -b $RANDOM -n "$i"_OP-bootreps -s "$i"_alignments.phylip -q "$i"_OP.partitions"    >>"$i"_OP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_OP_raxml.pbs.sh
    echo "#run RAxML and add bootstrap bipartition frequencies to best tree"                                                                                                        >>"$i"_OP_raxml.pbs.sh
    echo "raxmlHPC -m GTRGAMMA -f b -t RAxML_bestTree."$i"_OP-best -z RAxML_bootstrap."$i"_OP-bootreps"                                                                             >>"$i"_OP_raxml.pbs.sh
    echo ""                                                                                                                                                                         >>"$i"_OP_raxml.pbs.sh
    echo "#run RAxML and test for boostrap convergence"                                                                                                                             >>"$i"_OP_raxml.pbs.sh
    echo "raxmlHPC -m GTRGAMMA -z RAxML_bootstrap."$i"_OP-bootreps -I autoMRE -p $RANDOM -n converge"                                                                               >>"$i"_OP_raxml.pbs.sh
     
    cd $WORK_DIR

    #create file in the working directory that will recursivley submit all *_OP_RAxML jobs at once.
    echo "cd $WORK_DIR/"$i"_OP_raxml;  qsub "$i"_OP_raxml.pbs.sh;  cd $WORK_DIR" >>qsub_OP_raxml.sh

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#  [4] E X A B A Y E S    N O    P A R T I T I O N
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #move into directory to create files for unpartitioned exabayes
    cd $WORK_DIR/"$i"_UP_exabayes
   
    #if an unpartitioned exabayes qsub file exists...delete it
    if [ -f "$i"_UP_exabayes.pbs.sh ]
        then
        rm "$i"_UP_exabayes.pbs.sh
    fi

    #exabayes requires a config file.  copy it from the bin directory
    cp $WORK_DIR/bin/100K-4C-4R_config.nex .

    #create a qsub file to run a full exaBayes run on the unpartitioned data 
    echo '#!/bin/bash'                                                                                                                                                  >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -V"                                                                                                                                                        >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -cwd"                                                                                                                                                      >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -S /bin/bash"                                                                                                                                              >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -N xB-"$i"-UP"                                                                                                                                             >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID"                                                                                                                                   >>"$i"_UP_exabayes.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID"                                                                                                                                   >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -q $QUEUE"                                                                                                                                                 >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -pe sm $BAYES_PROCESSORS"                                                                                                                                >>"$i"_UP_exabayes.pbs.sh
    echo "#$ -P communitycluster"                                                                                                                                       >>"$i"_UP_exabayes.pbs.sh
    echo ""                                                                                                                                                             >>"$i"_UP_exabayes.pbs.sh
    echo "mpirun --mca mtl ^psm -np $BAYES_PROCESSORS exabayes -m DNA -M 3 -C 4 -R 4 -s $RANDOM -c 100K-4C-4R_config.nex -f "$i"_alignments.phylip -n 100K-4C-4R-"$i"-UP"    >>"$i"_UP_exabayes.pbs.sh
    echo ""                                                                                                                                                             >>"$i"_UP_exabayes.pbs.sh
    echo "consense -f ExaBayes_topologies.100K-4C-4R-"$i"-UP.* -n "$i"-UP_myCons"                                                                                       >>"$i"_UP_exabayes.pbs.sh
    echo ""                                                                                                                                                             >>"$i"_UP_exabayes.pbs.sh
    echo "postProcParam -f ExaBayes_parameters.100K-4C-4R-"$i"-UP.* -n "$i"-UP_params"                                                                                  >>"$i"_UP_exabayes.pbs.sh
    echo ""                                                                                                                                                             >>"$i"_UP_exabayes.pbs.sh
    echo "extractBips -f ExaBayes_topologies.100K-4C-4R-"$i"-UP.* -n "$i"-UP_bls"                                                                                       >>"$i"_UP_exabayes.pbs.sh

    cd $WORK_DIR

    #create file in the working directory that will recursivley submit all *_UP_exaBayes jobs at once.
    echo "cd $WORK_DIR/"$i"_UP_exabayes;  qsub "$i"_UP_exabayes.pbs.sh;  cd $WORK_DIR" >>qsub_UP_exabayes.sh


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#  [5] E X A B A Y E S    F U L L    P A R T I T I O N
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #move into the fully paritioned exaBayes directory
    cd $WORK_DIR/"$i"_FP_exabayes


    #if a full partition exabayes qsub file exists...delete it
    if [ -f "$i"_FP_exabayes.pbs.sh ]
        then
        rm "$i"_FP_exabayes.pbs.sh
    fi

    #exabayes requires a config file.  copy it from the bin directory
    cp $WORK_DIR/bin/100K-4C-4R_config.nex .

    #create a qsub file to run a full exaBayes run on the fully partitioned data 
    echo '#!/bin/bash'                                                                                                                                                                      >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -V"                                                                                                                                                                            >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -cwd"                                                                                                                                                                          >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -S /bin/bash"                                                                                                                                                                  >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -N xB-"$i"-FP"                                                                                                                                                                 >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID"                                                                                                                                                       >>"$i"_FP_exabayes.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID"                                                                                                                                                       >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -q $QUEUE"                                                                                                                                                                     >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -pe sm $BAYES_PROCESSORS"                                                                                                                                                    >>"$i"_FP_exabayes.pbs.sh
    echo "#$ -P communitycluster"                                                                                                                                                           >>"$i"_FP_exabayes.pbs.sh
    echo ""                                                                                                                                                                                 >>"$i"_FP_exabayes.pbs.sh
    echo "mpirun --mca mtl ^psm -np $BAYES_PROCESSORS exabayes -m DNA -M 3 -C 4 -R 4 -s $RANDOM -c 100K-4C-4R_config.nex -f "$i"_alignments.phylip -n 100K-4C-4R-"$i"-FP -q "$i".partitions"     >>"$i"_FP_exabayes.pbs.sh
    echo ""                                                                                                                                                                                 >>"$i"_FP_exabayes.pbs.sh
    echo "consense -f ExaBayes_topologies.100K-4C-4R-"$i"-FP.* -n "$i"-FP_myCons"                                                                                                           >>"$i"_FP_exabayes.pbs.sh
    echo ""                                                                                                                                                                                 >>"$i"_FP_exabayes.pbs.sh
    echo "postProcParam -f ExaBayes_parameters.100K-4C-4R-"$i"-FP.* -n "$i"-FP_params"                                                                                                      >>"$i"_FP_exabayes.pbs.sh
    echo ""                                                                                                                                                                                 >>"$i"_FP_exabayes.pbs.sh
    echo "extractBips -f ExaBayes_topologies.100K-4C-4R-"$i"-FP.* -n "$i"-FP_bls"                                                                                                           >>"$i"_FP_exabayes.pbs.sh

    cd $WORK_DIR

    #create file in the working directory that will recursivley submit all *_FP_exaBayes jobs at once.
    echo "cd $WORK_DIR/"$i"_FP_exabayes;  qsub "$i"_FP_exabayes.pbs.sh;  cd .." >>qsub_FP_exabayes.sh

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#  [6] E X A B A Y E S    O P T I M U M    P A R T I T I O N
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    cd $WORK_DIR/$i"_OP_exabayes"

    #if an optimum partition exabayes qsub file exists...delete it
    if [ -f "$i"_OP_exabayes.pbs.sh ]
        then
        rm "$i"_OP_exabayes.pbs.sh
    fi

    #exabayes requires a config file.  copy it from the bin directory
    cp $WORK_DIR/bin/100K-4C-4R_config.nex .

    # IMPORTANT NOTE!!!!!!!!!!!!!!!!!!!!!!!
    #keep in mind, since we are copying the partitions file from the RAxML PartitionFinder run
    #  then the exaBayes OP run can't start untill those files are created.  RUN IT LAST

    echo '#!/bin/bash'                                                                                                                                                                          >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -V"                                                                                                                                                                                >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -cwd"                                                                                                                                                                              >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -S /bin/bash"                                                                                                                                                                      >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -N xB-"$i"-OP"                                                                                                                                                                     >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -o \$JOB_NAME.o\$JOB_ID"                                                                                                                                                           >>"$i"_OP_exabayes.pbs.sh   
    echo "#$ -e \$JOB_NAME.e\$JOB_ID"                                                                                                                                                           >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -q $QUEUE"                                                                                                                                                                         >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -pe fill $BAYES_PROCESSORS"                                                                                                                                                        >>"$i"_OP_exabayes.pbs.sh
    echo "#$ -P communitycluster"                                                                                                                                                               >>"$i"_OP_exabayes.pbs.sh
    echo ""                                                                                                                                                                                     >>"$i"_OP_exabayes.pbs.sh
    echo "cp ../"$i"_OP_raxml/"$i"_OP.partitions ."                                                                                                                                             >>"$i"_OP_exabayes.pbs.sh
    echo "mpirun --mca mtl ^psm -np $BAYES_PROCESSORS exabayes -m DNA -M 3 -C 4 -R 4 -s $RANDOM -c 100K-4C-4R_config.nex -f "$i"_alignments.phylip -n 100K-4C-4R-"$i"-OP -q "$i"_OP.partitions"      >>"$i"_OP_exabayes.pbs.sh
    echo ""                                                                                                                                                                                     >>"$i"_OP_exabayes.pbs.sh
    echo "consense -f ExaBayes_topologies.100K-4C-4R-"$i"-FP.* -n "$i"-OP_myCons"                                                                                                               >>"$i"_OP_exabayes.pbs.sh
    echo ""                                                                                                                                                                                     >>"$i"_OP_exabayes.pbs.sh
    echo "postProcParam -f ExaBayes_parameters.100K-4C-4R-"$i"-OP.* -n "$i"-OP_params"                                                                                                          >>"$i"_OP_exabayes.pbs.sh
    echo ""                                                                                                                                                                                     >>"$i"_OP_exabayes.pbs.sh
    echo "extractBips -f ExaBayes_topologies.100K-4C-4R-"$i"-OP.* -n "$i"-OP_bls"                                                                                                               >>"$i"_OP_exabayes.pbs.sh

    cd $WORK_DIR

    #create file in the working directory that will recursivley submit all *_OP_exaBayes jobs at once.
    echo "cd $WORK_DIR/"$i"_OP_exabayes;  qsub "$i"_OP_exabayes.pbs.sh;  cd "$WORK_DIR >>qsub_OP_exabayes.sh

done
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------



#make all batch qsub scripts executable
chmod u+x qsub_FP_exabayes.sh  qsub_FP_raxml.sh  qsub_UP_raxml.sh  qsub_UP_exabayes.sh qsub_OP_exabayes.sh qsub_OP_raxml.sh












