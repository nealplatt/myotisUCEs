
WORK_DIR=/home/roplatt/myotisUCEs/neal/play

cd $WORK_DIR


for i in 15 25 35 45 55 65 75 85 95 100
do

    cd $WORK_DIR
    
    mkdir $i"_svdquartets"
    cd $i"_svdquartets"



    cp ../$i"_FP_raxml"/$i"_alignments.phylip" . 
    cp ../$i"_FP_raxml"/$i"_alignments.charsets" .

    NCHAR=$(head -n 1 $i"_alignments.phylip" | cut -f2 -d" ")
    NTAXA=$(head -n 1 $i"_alignments.phylip" | cut -f1 -d" ")


    if [ -f $i"_svdquartets.nex" ]
        then
        rm $i"_svdquartets.nex"
    fi

    touch $i"_svdquartets.nex"

    echo -e "#NEXUS"                                    >>$i"_svdquartets.nex"
    echo ""                                             >>$i"_svdquartets.nex"
    echo -e "begin data;"                               >>$i"_svdquartets.nex"
    echo -e "\tdimensions ntax=$NTAXA nchar=$NCHAR;"    >>$i"_svdquartets.nex"
    echo -e "\tformat datatype=dna gap=-;"              >>$i"_svdquartets.nex"
    echo -e "\tmatrix"                                  >>$i"_svdquartets.nex"
    sed '1d' $i"_alignments.phylip"                     >>$i"_svdquartets.nex"
    echo -e "\t;"                                       >>$i"_svdquartets.nex"
    echo "end;"                                         >>$i"_svdquartets.nex"
    echo ""                                             >>$i"_svdquartets.nex"
    #cat $i"_alignments.charsets"                        >>$i"_svdquartets.nex"
    #echo ""                                             >>$i"_svdquartets.nex"

    echo -e "begin PAUP;"                                                                       >>$i"_svdquartets.nex"
    echo -e "\tlog file="$i"_svdquartets.log start replace;"                                    >>$i"_svdquartets.nex"
    echo -e "\tsvdquartets evalQuartets=random bootstrap=yes nreps=100 nthreads=3"              >>$i"_svdquartets.nex"
    echo -e "\t\ttreeFile="$i"_svdquartets.bootreps nquartets=200000;"                          >>$i"_svdquartets.nex"
    echo -e "\tsavetrees from=1 to=1 savebootp=nodelabels file="$i"_svdquartets_cons.tree;"     >>$i"_svdquartets.nex"
    echo -e "\tlog stop;"                                                                       >>$i"_svdquartets.nex"
    echo -e "\tquit;"                                                                           >>$i"_svdquartets.nex"
    echo -e "end;"                                                                              >>$i"_svdquartets.nex"
    
    cd $WORK_DIR

done


#paup doesn't run on the hpcc so each svdquartets dir was downloaded and run locally using this loop
#for i in 15 25 35 45 55 65 75 85 95 100
#do
#    cd $i"_svdquartets"
#    ../../paup4a149_ubuntu64 $i"_svdquartets.nex" 
#    cd ..
#done


