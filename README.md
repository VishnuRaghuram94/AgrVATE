### agr_fs_detect.sh 
###### Vishnu Raghuram 2020-11-12 
###### bash script for detecting S. aureus agr group from genome assembly and calling variants in agr operon using group-specific reference
&nbsp;

### PREREQUISITES:
	[Usearch 32 bit linux](https://drive5.com/usearch/)
	[Snippy](https://github.com/tseemann/snippy)
	[HMMER](http://hmmer.org/)
	databases file for agr group typing and variant calling
	databases/
			├── agr_operon_primers.fa
			├── gp1234_motifs.fasta
			├── agrD_hmm.hmm
			└── references
				├── gp1-operon_ref.gbk
				├── gp2-operon_ref.gbk
				├── gp3-operon_ref.gbk
				└── gp4-operon_ref.gbk

			
&nbsp;	
---

### USAGE:
	agr_fs_detect.sh <fasta_file> <path_to_databases>
	
	* <fasta_file> : S. aureus genome assembly in fasta format. Can also be S. aureus metagenome. 
	* <path_to_databases>  : Absolute path to database files. Default " ./databases "
&nbsp;
---

### OUTPUTS:

A new directory with suffix -results will be created

***NOTE:*** **There are 15 possible kmers for each agr group. The analyses will continue even if only one kmer matches a given agr-group but it should be noted that < 5 kmers matching leads to a low confidence agr-group call. Please check fasta-agr_gp.tab for the number of kmers matched.** 

	* fasta-agr_gp.tab: 
		col 1: Accession
		col 2: Contig ID
		col 3: ID of matched agr group kmer
		col 4: Percentage identity of match
		
	* fasta-agr_operon.fna:
		Agr operon extracted from in-silico PCR using USEARCH -SEARCH_PCR in fasta format
	
	*fasta-agr_operon_frameshifts.tab
		Frameshift mutations in extracted agr operon detected by Snippy. An agr-group specific reference sequence is used to call variants. 
	
	* fna-usearch_log.txt:
		Tabular output of [USEARCH -SEARCH_OLIGODB](https://drive5.com/usearch/manual/cmd_search_oligodb.html)
	
	* fasta-hmm.tab:
		Standard output of [nhmmer](http://hmmer.org/documentation.html)
		This file is present only if the agr group is untypeable. 
	
	* fasta-agr_operon_frameshifts.tab
		Standard output of [USEARCH -SEARCH_PCR](https://drive5.com/usearch/manual/cmd_search_pcr.html)
	
	*fasta-snippy_log.txt:
		Standard output of [Snippy](https://github.com/tseemann/snippy)
		
	*snippy/
		All output files of [Snippy](https://github.com/tseemann/snippy)
