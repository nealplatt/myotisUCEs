#this was run on my local computer
WORK_DIR=/home/neal/Desktop/astrid


for i in 15 25 35 45 55 65 75 85 95 100
do

    cd $WORK_DIR
    
    mkdir $WORK_DIR/$i"_astrid"
    mkdir $WORK_DIR/$i"_astridBoot"
    
    cd $WORK_DIR/$i"_astrid"

    #create file of input gene trees (newick format)
    cat $WORK_DIR/$i"_geneTrees"/* >$i"_geneTrees.trees"
    
    #use astrid to calculate the species tree
    ../../ASTRID -i $i"_geneTrees.trees" -m bionj -o $i"_astrid_speciesTree.tree" > $i"_astrid_speciesTree.log" 2>&1




    cd $WORK_DIR/$i"_astridBoot"
    
    ls $WORK_DIR/$i"_bootTrees"/* >$i"_bootTrees.list"
    cat $WORK_DIR/$i"_geneTrees"/* >$i"_geneTrees.trees"

    #boostrap astrid species tree
    ../../ASTRID -i $i"_geneTrees.trees" -m bionj -b 100 -b $i"_bootTrees.list" -o $i"_astrid_bootSpeciesTree.tree" > $i"_astrid_bootSpeciesTree.log" 2>&1

    cd $WORK_DIR

done


