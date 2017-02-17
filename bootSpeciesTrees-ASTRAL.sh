WORK_DIR=/home/roplatt/myotisUCEs/neal/play


for i in 100 15 95 25 85 35 75 45 65 55
do

    cd $WORK_DIR
    
    #mkdir $WORK_DIR/$i"_astralBoot"
    
    cd $WORK_DIR/$i"_astralBoot"

    #create file of input gene trees (newick format)
    cat $WORK_DIR/$i"_geneTrees"/* >$i"_geneTrees.trees"
    ls $WORK_DIR/$i"_bootTrees"/* >$i"_bootTrees.list"


    #bootstrap ASTRAL tree site/locus resampling
    grCMD="java -jar ../bin/ASTRAL/astral.4.10.6.jar --input $i"_geneTrees.trees" -b $i"_bootTrees.list" -g -r 100 --output $i"_ASTRAL_siteLocus100_boot.tree" >$i"_ASTRAL_siteLocus100_boot.log" 2>&1"

    #bootstrap ASTRAL tree site resampling
    rCMD="java -jar ../bin/ASTRAL/astral.4.10.6.jar --input $i"_geneTrees.trees" -b $i"_bootTrees.list" -r 100 --output $i"_ASTRAL_site100_boot.tree" >$i"_ASTRAL_site100_boot.log" 2>&1" 

    echo $grCMD | qsub -N gr"$i"astral -o gr"$i"astral.o -e gr"$i"astral.e -P communitycluster -q Yoda -pe fill 1 -cwd -V -S /bin/bash
    echo $rCMD | qsub -N r"$i"astral -o r"$i"astral.o -e r"$i"astral.e -P communitycluster -q Yoda -pe fill 1 -cwd -V -S /bin/bash


done

