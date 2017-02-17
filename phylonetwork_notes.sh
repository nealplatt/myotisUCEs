Running Phylonetworks.
======================

### Step 1 run RAxML to bootstrap gene/species trees with RAxML and ASTRAL.

```bash
#Setting up directory (hrothgar)

WORK_DIR=/home/roplatt/myotisUCEs/neal/play
QUEUE=Chewie


cd $WORK_DIR


mkdir phylonetwork

cd phylonetwork

#FOR TEST PURPOSES ONLY USING THE LONGEST (MOST VARIABLE) ALIGNMENTS - initial runs with the full data setseem to indicate that this process is very time consuming.  all 3.6K trees took over 20Gb of memory and only made it through 8% of the LOADING process in ~24 hours.

cp -r $WORK_DIR/sortedByLength/09/alignments ./longest_10perc_align

#running raxml (1k bootstrap replicates)
mkdir longest_10perc_raxml

cd longest_10perc_raxml/

#use a for loop to submit all the RAxML jobs to Chewie.
for i in $(ls ../longest_10perc_align/)
do

    UCE=$(basename $i .phylip-relaxed)
    CMD="raxmlHPC -f a -m GTRGAMMA -p $RANDOM -x $RANDOM -# 1000 -s ../longest_10perc_align/$i -n $UCE"-boot""
    echo $CMD | qsub -N $UCE -o $UCE.o -e $UCE.e -P communitycluster -q Chewie -pe fill 1 -cwd -V -S /bin/bash

done
```




This generates the all the necessary gene trees (on hrothgar) These GTs need to be prepped and run through ASTRAL (bootstrapped). 
```bash
cd ..

mkdir longest_10perc_astral
cd longest_10perc_astral/

ls /home/roplatt/myotisUCEs/neal/play/phylonetwork/longest_10perc_raxml/RAxML_bipartitions.uce-*-boot >bootList

cat longest_10perc_raxml/RAxML_bestTree.uce-* >raxmlBestTrees.tree

CMD="java -jar ../../bin/ASTRAL/astral.4.10.6.jar -i raxmlBestTrees.tree -b bootList -r 500 -o astral.tree > astral.screenlog 2>&1"
echo $CMD | qsub -N ASTRAL -o ASTRAL.o -e ASTRAL.e -P communitycluster -q Chewie -pe fill 1 -cwd -V -S /bin/bash
```
### PhyloNetworkds

Now that the gene/species tree has been generated, this data can be used to generate the phylonetwork.  All of this is installed on my local computer and not Hrothgar (julia/phylonetworks).  

Working from the pipeline given here: https://github.com/crsl4/PhyloNetworks.jl/wiki:

working in ~/Desktop/phylonetworks directory.  PhyloNetworks needs the RAxML best trees for each locus (in a single file - raxmlBestTrees.tree) and the ASTRAL tree (astral.tree) that includes the bootsrap replicates.

Everything is run in JULIA

```bash
julia

Pkg.add("PhyloNetworks")

Pkg.update()

using PhyloNetworks;

raxmlCF = readTrees2CF("raxmlBestTrees.tree", writeTab=false, writeSummary=false)
```
so once I got to this point it is time to read in the astral tree (from the bootstrap analysis of 500 replicates)

```bash
astraltree = readMultiTopology("astral.tree")[502]
could not read tree on line 78 of file astral.tree. error was this:
ERROR: Expected right parenthesis after left parenthesis 32 but read E. The remainder of line is -4)1:0.33934347143143717,((myotis_thysanodes_07LEP,(myotis_evotis_MSB47323,myotis_keeni_AF74075)1:0.1760759695121143)1:0.3670639193552491,(myotis_septentrionalis_RDS7705,myotis_auriculus_MSB40883)1:0.286056822776081)0.93:0.0828773350037928)1:0.311220424568167));.
 in error at ./error.jl:21
 in readSubtree! at /home/neal/.julia/v0.4/PhyloNetworks/src/readwrite.jl:127
 in readSubtree! at /home/neal/.julia/v0.4/PhyloNetworks/src/readwrite.jl:121 (repeats 2 times)
 in readTopology at /home/neal/.julia/v0.4/PhyloNetworks/src/readwrite.jl:369
 in readTopology at /home/neal/.julia/v0.4/PhyloNetworks/src/readwrite.jl:336
 in readMultiTopology at /home/neal/.julia/v0.4/PhyloNetworks/src/readwrite.jl:1104
```

This error is a result of scientific notation 2.904E-4 (ex).  Since these values are only in the bootstrap replicates, I removed them from the file (snaq! is only interested in the ASTRAL tree.

```bash
grep -v E- astral.tree | wc -l >astralNoEs.tree
```

Now I ran the first iteration of snaq!

```bash
net0=snaq!(astraltree,raxmlCF,hmax=0, filename="snaq/net0_raxml")
```



