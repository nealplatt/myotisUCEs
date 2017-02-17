WORK_DIR=/home/roplatt/myotisUCEs/neal/play


for i in 15 25 35 45 55 65 75 85 95 100
do

    cd $WORK_DIR
    
    mkdir $WORK_DIR/$i"_astral"
    
    cd $WORK_DIR/$i"_astral"

    #create file of input gene trees (newick format)
    cat $WORK_DIR/$i"_geneTrees"/* >$i"_geneTrees.trees"


    #ASTRAL tree wtih quartet support for the main resolution
    java -jar ../bin/ASTRAL/astral.4.10.6.jar --input $i"_geneTrees.trees" --branch-annotate 1 --output $i"_ASTRAL_quartetSupport.tree" > $i"_ASTRAL_quartetSupport.log" 2>&1 &


    #full annotation of tree (quartet support, quartet frequency, posterior prob for all three alternatives, number of quartets (per branch) and effective number of genes)
    java -jar ../bin/ASTRAL/astral.4.10.6.jar --input $i"_geneTrees.trees" --branch-annotate 2 --output $i"_ASTRAL_fullAnnotation.tree" > $i"_ASTRAL_fullAnnotation.log" 2>&1 &

    #posterior probability of main resolutionn
    java -jar ../bin/ASTRAL/astral.4.10.6.jar --input $i"_geneTrees.trees" --branch-annotate 3 --output $i"_ASTRAL_posteriorProbability.tree" > $i"_ASTRAL_posteriorProbability.log" 2>&1 &


done

wait
