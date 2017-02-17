WORK_DIR=/home/roplatt/myotisUCEs/neal/play/sortedByLength

mkdir $WORK_DIR

#directory to sample alignments from (this should be the 15_alignments dir)
ALIGNMENTS_DIR=../15_geneTrees_raxml/15_alignments_phylip

RAXML_BOOTREPS=100
RAXML_PROCESSORS=10



BIN_DIR=/home/roplatt/myotisUCEs/neal/play/bin


cd $WORK_DIR

#copy all phylip alignments for simplicity
mkdir phylipAlignments
cp $ALIGNMENTS_DIR/uce-*relaxed phylipAlignments/



for i in $(ls phylipAlignments/*phylip-relaxed)
    do 
      SIZE=$(head -1 $i | cut -f 3 -d" ")
      echo $SIZE $i 
    done | sort -n >loci.sizes

    cut -f2 -d" " loci.sizes >loci.names

split -d -l 365 loci.names sorted_loci.sizes



for i in 00 01 02 03 04 05 06 07 08 09

    do

    mkdir $i
    mkdir $i/alignments
    
    cd $i

    while read SORTED
    do
        cp $WORK_DIR/$SORTED alignments

    done < $WORK_DIR/sorted_loci.sizes"$i"


    #convert to nexus
    phyluce_align_convert_one_align_to_another --alignments alignments/ --output alignments_nexus --input-format phylip-relaxed --output-format nexus --cores 1

    #convert nexus to raxml
    phyluce_align_format_nexus_files_for_raxml --alignments alignments_nexus/ --output raxml --charsets

    mv raxml/alignments_nexus.charsets raxml/bySize_"$i".charsets
    mv raxml/alignments_nexus.phylip raxml/bySize_"$i".phylip

    #convert partitions to raxml
    perl $BIN_DIR/raxml_nexusPartConvert.pl -m raxml/bySize_"$i".charsets -r DNA >raxml/bySize_"$i".partitions


    cd raxml
    #submit
    CMD="mpirun --mca mtl ^psm -np $RAXML_PROCESSORS raxmlHPC-MPI -f a -m GTRGAMMA -p $RANDOM -x $RANDOM -# $RAXML_BOOTREPS -s bySize_"$i".phylip -n bySize_"$i" -q bySize_"$i".partitions"
    echo $CMD | qsub -N size$i -o size$i.o -e size$i.e -P communitycluster -q Chewie -pe fill 10 -cwd -V -S /bin/bash
    



    cd $WORK_DIR
    done
