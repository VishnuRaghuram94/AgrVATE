#!/bin/bash

#Vishnu Raghuram 2020-11-12
#bash script for extracting intact agr operons from S. aureus and identifying frameshift mutations using agr-group specific references 

USAGE=$(echo -e "USAGE: agr_fs_detect.sh <fasta file> <path to databases>\n")


#Check if input is empty
if [ -z "$1" ] 
then
	echo -e "No input file given\n$USAGE"
	exit
else
	fna_name=$(basename $1)
fi
 
#assume current directory if path to database not specified. 
if [ -z "$2" ]
then
	databases_path="./databases"
else
	databases_path=$2
fi

#check if results directory already exists
if [ -d $fna_name-results ]
then
	echo "Results directory already exists, cannot overwrite"
	exit
else	
	mkdir $fna_name-results
fi



################################
#### AGR TYPING KMER SEARCH ####
################################

#fna file searched against agr typing kmers using usearch oligodb and write output to agrgp_tab
usearch11.0.667_i86linux32 -search_oligodb $1 -db $databases_path/gp1234_motifs.fasta  -maxdiffs 0 -userfields query+target+evalue+id -strand both -userout $fna_name-results/$fna_name-agr_gp.tab &>$fna_name-results/$fna_name-usearch_log.txt

#identify agr group from search_oligodb results
if [ -z $(cat $fna_name-results/$fna_name-agr_gp.tab | cut -f2 | sort | uniq | cut -f1 -d"|" | uniq) ]
then
	echo -e "Unable to agr type\n"
	exit
# elif [ $(wc -l <file.txt) -ge 2 ]
# then
	# echo -e "Fasta file has more than one agr type (multiple S. aureus sequences)\n"
	# :
else
	agr_gp=$(cat $fna_name-results/$fna_name-agr_gp.tab | cut -f2 | sort | uniq | cut -f1 -d"|" | uniq)
	echo -e "agr typing successful, $agr_gp"
fi


#################################
##### EXTRACTING AGR OPERON #####
#################################

#In-silico PCR using predefined primers(agr_operon_primers.fa) to extract agr operon
usearch11.0.667_i86linux32 -search_pcr $1 -db $databases_path/agr_operon_primers.fa -strand both -maxdiffs 8 -minamp 3000 -maxamp 5000 -ampout $fna_name-results/$fna_name-agr_operon.fna &>$fna_name-results/$fna_name-pcr-log.txt

#Check if agr operon file is empty
if [ -s $fna_name-results/$fna_name-agr_operon.fna ] 
then
	echo -e "agr operon extraction successful"
else	
	echo -e "Unable to find agr operon, check $fna_name-results/$fna_name-pcr-log.txt"
	exit	
fi


################################
##### FRAMESHIFT DETECTION #####
################################

#Running snippy with a group specific reference to call variants in the agr operon
snippy --outdir $fna_name-results/snippy --ctgs $fna_name-results/$fna_name-agr_operon.fna --ref $databases_path/references/$agr_gp-operon_ref.gbk 2> $fna_name-results/$fna_name-snippy-log.txt

#Check if snps file is empty
if [ -s $fna_name-results/snippy/snps.tab ] 
then
	echo -e "Snippy successful"
else	
	echo -e "Snippy unsuccessful, check $fna_name-results/$fna_name-snippy-log.txt"
	exit	
fi

#Filtering out frameshifts in coding regions from snippy data
awk -v i="$fna_name-results" 'BEGIN{FS=OFS="\t"};{if($7=="CDS") print i,$2,$3,$11,$13}' $fna_name-results/snippy/snps.tab | sed 's/ /\t/g' | grep -E -v 'missense_variant' | grep -E -v 'synonymous_variant' > $fna_name-results/$fna_name-agr_operon_frameshifts.tab


#Check if frameshifts file is empty
if [ -s $fna_name-results/$fna_name-agr_operon_frameshifts.tab ] 
then
	echo -e "Frameshifts in agr operon found, check $fna_name-results/$fna_name-agr_operon_frameshifts.tab"
else	
	echo -e "No frameshifts found"
	exit	
fi
