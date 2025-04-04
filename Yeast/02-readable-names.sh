#!/bin/sh -e

##########################################################################
#   Description:
#       Give raw files meaningful names that are easy to manage
#       in the scripts that follow
##########################################################################

##########################################################################
#   Main
##########################################################################

# Document software versions used for publication
uname -a
pwd

raw=Results/01-fetch
raw_renamed=Results/02-readable-names
mkdir -p $raw_renamed
rm -f $raw_renamed/*

# There are 2 raw files for each replicate
replicates=$(($(ls $raw | wc -l) / 2))

# Link raw files to WT-rep or SNF-rep to indicate the biological condition
# Link raw files to condX-repYY for easy and consistent scripting
# I usually make cond1 the control (e.g. wild-type) or first time point
map=ERP004763_sample_mapping.tsv
sample_num=1
tech_rep=1  # Fixed, could be 1 through 7
# Select $replicates replicates
# Get one technical replicate from each biological replicate
# Col 2 (Lane) indicates technical rep, use samples where Lane = 1
# Col 3 is SNF2 mutant or WT
# Col 4 is biological replicate
# printf "$condition:\n"

for fq in $(ls Results/01-fetch/); do
    sample=${fq%.fastq.zst}
    # Use 2 digits for all replicates in filenames for "ls" sort order
    biorep=$(awk -v sample=$sample '$1 == sample { print $4 }' $map)
    condition=$(awk -v sample=$sample '$1 == sample { print $3 }' $map)
    if [ $condition = WT ]; then
	cond_num=1
    else
	cond_num=2
    fi
    printf "Linking $sample = $condition-$biorep = cond$cond_num-rep$biorep...\n"
    biorep_padded=$(printf "%02d" $biorep)
    sample_num_padded=$(printf "%02d" $sample_num)
    # Use soft/symbolic links (ln -s) in case raw files are on a different
    # disk/partition.  Hard links won't work in that case.
    (cd $raw_renamed && ln -fs ../01-fetch/$fq $condition-$biorep_padded.fastq.zst)
    (cd $raw_renamed && ln -fs ../01-fetch/$fq sample$sample_num_padded-cond$cond_num-rep$biorep_padded.fastq.zst)
    sample_num=$(($sample_num + 1))
done
rm -f $condition.tsv
ls -l $raw_renamed
