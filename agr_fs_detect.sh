#!/bin/bash

#Vishnu Raghuram 2020-11-12
#bash script for extracting intact agr operons from S. aureus and identifying frameshift mutations using agr-group specific references 


USAGE=$(echo -e "USAGE: agr_fs_detect.sh <fasta file> <path to databases>\nCheck README file for prerequsites\nagr_fs_detect.sh -h #to print this help message\nagr_fs_detect.sh -v #to print version\n")

#Help and version options
while getopts ":hv" option; do
	case $option in 
		h) #Print usage if option -h is given
		echo -e "$USAGE"
		exit;;
	
		v) #Print version number if option -v is given
		echo -e "version 1.0"
		exit;;
	
		\?) #Exit if invalid option
		echo -e "Unknown option\n$USAGE"
		exit;;
	esac
done

#validate input fasta

if [ -z "$1" ]
then
	echo -e "No input file given\n$USAGE"
	exit
else
	if [ -f "$1" ] #Check if input is a file
	 then
		if [[ $(file $1 | grep -c "compressed") == 0 ]] #checks if file is compressed
		 then	
			if [[ $(grep -q "^@" $1 ; echo $?) == 1 && $(seqkit seq -t dna -n --quiet $1 | wc -l) -ge 1 ]] # if file is NOT fastq and checks if seqkit can parse the file 
			 then	
				if [[ $(grep -v ">" $1 | grep -q "[^ATCGN]"; echo $?) == 1 ]] #check if seqence has characters other than ATGCN
				 then
					bname=$(basename $1)
					fna_name=$(echo "$bname" | cut -f1 -d".")
				else
					echo -e "Seqence has non-standard nucleic acid characters\n$USAGE"
					exit
				fi
			else
				echo -e "Invalid input\n$USAGE"
				exit
			fi
		else
			echo -e "Compressed input not supported (for now)\n$USAGE"
			exit
		fi	
	else
		echo -e "Invalid input\n$USAGE"
		exit
	fi
fi


#assume current directory if path to database not specified. 
if [ -z "$2" ]
then
	databases_path="./databases"
else
	databases_path=$2
fi

#check if results directory already exists
if [[ -d $fna_name-results ]]
then
	echo "Results directory already exists, cannot overwrite"
	exit
else	
	mkdir $fna_name-results
fi



################################
#### AGR TYPING KMER SEARCH ####
################################

#fna file searched against agr typing kmers using blastn and write output to agrgp_tab
blastn -query $databases_path/gp1234_all_motifs.fna -subject $1 -outfmt "6 sseqid qseqid evalue pident sstart send" -max_hsps 1 -perc_identity 100 -qcov_hsp_perc 100 -out $fna_name-results/$fna_name-agr_gp.tab &>$fna_name-results/$fna_name-blastn_log.txt

#identify agr group from search_oligodb results

#check no. of agr group kmers matched. exit if more than one agr group found
if [[ $(cat $fna_name-results/$fna_name-agr_gp.tab | cut -f2 | sort | uniq | cut -f1 -d"|" | uniq | wc -l) -ge 2 ]]
 then #multiple agr groups
	echo -e "Fasta file has more than one agr type (multiple S. aureus sequences)\n Choosing highest confidence agr type"
	
	#top agr gp match
	agr_gp=$(cat $fna_name-results/$fna_name-agr_gp.tab  | cut -f2 | sort | uniq | cut -f1 -d"|" | uniq -c | sort -k1 -nr | head -1 | sed 's/^\s\+//g' | cut -f2 -d " ")
	
	#score for top agr gp match
	agr_match=$(cat $fna_name-results/$fna_name-agr_gp.tab  | cut -f2 | sort | uniq | cut -f1 -d"|" | uniq -c | sort -k1 -nr | head -1 | sed 's/^\s\+//g' | cut -f1 -d " ")	
	
	multiple="m"
	canonical=1
	
	#if top match is low confidence
	if [[ $agr_match -le 4 ]]
	 then
		echo -e "Multiple agr types found all with low confidence. Cannot proceed to frameshift detection"
		canonical="u"
		fs="u"
		#summary file
		echo -e "$fna_name\t$agr_gp\t$agr_match\t$canonical\t$multiple\t$fs" > $fna_name-results/$fna_name-summary.tab
		exit
	fi	
else #single agr group
	
	agr_match=$(cat $fna_name-results/$fna_name-agr_gp.tab | wc -l)
	#Check match score. if 0 then unknown type. if less than 4 then low confidence type. In both cases hmm search for agrD will be done.	
	if [[ $agr_match == 0 ]]
	 then
		echo -e "Unable to agr type"
		multiple="u"
		agr_gp="u"
		agrD_nhmmer=1
		
	elif [[ $agr_match -le 4 ]]
	 then
		echo -e "Low confidence agr-typing"
		multiple="s"
		agrD_nhmmer=1
		agr_gp=$(cat $fna_name-results/$fna_name-agr_gp.tab | cut -f2 | sort | uniq | cut -f1 -d"|" | uniq)

	else
		multiple="s"
		agr_gp=$(cat $fna_name-results/$fna_name-agr_gp.tab | cut -f2 | sort | uniq | cut -f1 -d"|" | uniq)
		canonical=1
		echo -e "agr typing successful, $agr_gp"
	fi
fi
	

###########################
#### NOVEL agrD SEARCH ####
###########################

if [[ $agrD_nhmmer == 1 ]]
 then
	#use nhmmer to search for sequence matching canonical S. aureus agrD
	nhmmer --noali --tblout $fna_name-results/$fna_name-hmm.tab -E 0.01 $databases_path/agrD_hmm.hmm $1 > $fna_name-results/$fna_name-hmm-log.txt

	#Check if hmmer hit ~120bp long. if yes - possible non-canonical agrD. 
	if [[ -z $(grep -v "#" $fna_name-results/$fna_name-hmm.tab | sed 's/\s\+/\t/g' | awk 'BEGIN{FS=OFS="\t"};{if($6-$5 > 120) print $0};') ]]
	 then
		echo -e "Unable to find agrD"
		canonical=u
	else
		echo -e "Possible non-canonical S. aureus agrD found"
		canonical=0
	fi	
fi


#summary file
#echo -e "$fna_name\t$agr_gp\t$agr_match\t$canonical\t$multiple" > $fna_name-results/$fna_name-summary.tab

#################################
##### EXTRACTING AGR OPERON #####
#################################

#Check if usearch11.0.667_i86linux32 binary is in PATH
path_to_usearch=$(which usearch11.0.667_i86linux32)

if [[ -x $path_to_usearch ]]
 then
    echo -e "usearch found"
else
	echo -e "usearch11.0.667_i86linux32 not in path, cannot perform frameshift detection\n please download usearch11.0.667_i86linux32 from https://www.drive5.com/usearch/download.html"
	fs="u"
	#summary file
	echo -e "$fna_name\t$agr_gp\t$agr_match\t$canonical\t$multiple\t$fs" > $fna_name-results/$fna_name-summary.tab
	exit
fi


#In-silico PCR using predefined primers(agr_operon_primers.fa) to extract agr operon
usearch11.0.667_i86linux32 -search_pcr $1 -db $databases_path/agr_operon_primers.fa -strand both -maxdiffs 8 -minamp 3000 -maxamp 5000 -ampout $fna_name-results/$fna_name-agr_operon.fna &>$fna_name-results/$fna_name-pcr-log.txt

#Check if agr operon file is empty
if [[ -s $fna_name-results/$fna_name-agr_operon.fna ]] 
then
	echo -e "agr operon extraction successful"
else	
	echo -e "Unable to find agr operon, check $fna_name-results/$fna_name-pcr-log.txt"
	fs="u"
	#summary file
	echo -e "$fna_name\t$agr_gp\t$agr_match\t$canonical\t$multiple\t$fs" > $fna_name-results/$fna_name-summary.tab
	exit	
fi

if [[ $agr_gp == "u" ]]
then
	echo -e "Unable to determine agr group, cannot perform frameshift detection"
	fs="u"
	#summary file
	echo -e "$fna_name\t$agr_gp\t$agr_match\t$canonical\t$multiple\t$fs" > $fna_name-results/$fna_name-summary.tab
	exit
fi

################################
##### FRAMESHIFT DETECTION #####
################################

#Running snippy with a group specific reference to call variants in the agr operon
snippy --outdir $fna_name-results/$fna_name-snippy --ctgs $fna_name-results/$fna_name-agr_operon.fna --ref $databases_path/references/$agr_gp-operon_ref.gbk 2> $fna_name-results/$fna_name-snippy-log.txt

#Check if snps file is empty
if [[ -s $fna_name-results/$fna_name-snippy/snps.tab ]]
then
	echo -e "Snippy successful"
else	
	echo -e "Snippy unsuccessful, check $fna_name-results/$fna_name-snippy-log.txt"
	fs="u"
	#summary file
	echo -e "$fna_name\t$agr_gp\t$agr_match\t$canonical\t$multiple\t$fs" > $fna_name-results/$fna_name-summary.tab
	exit	
fi

#Filtering out frameshifts in coding regions from snippy data
awk -v i="$fna_name" 'BEGIN{FS=OFS="\t"};{if($7=="CDS") print i,$2,$3,$11,$13}' $fna_name-results/$fna_name-snippy/snps.tab | sed 's/ /\t/g' | grep -E -v 'missense_variant' | grep -E -v 'synonymous_variant' > $fna_name-results/$fna_name-agr_operon_frameshifts.tab

fs=$(cat $fna_name-results/$fna_name-agr_operon_frameshifts.tab | wc -l)
#summary file
echo -e "$fna_name\t$agr_gp\t$agr_match\t$canonical\t$multiple\t$fs" > $fna_name-results/$fna_name-summary.tab


#Check if frameshifts file is empty
if [[ -s $fna_name-results/$fna_name-agr_operon_frameshifts.tab ]] 
then
	echo -e "Frameshifts in agr operon found, check $fna_name-results/$fna_name-agr_operon_frameshifts.tab"
else	
	echo -e "No frameshifts found"
	exit	
fi

