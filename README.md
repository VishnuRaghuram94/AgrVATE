### agr_fs_detect.sh 
###### Vishnu Raghuram 2020-11-12 
###### bash script for detecting S. aureus agr group from genome assembly and calling variants in agr operon using group-specific reference


### PREREQUISITES:
* [Usearch 32 bit linux](https://drive5.com/usearch/)

	*Due to Usearch's license, it cannot be provided with the conda installation. Please download and extract usearch11.0.667 from [here](https://www.drive5.com/downloads/usearch11.0.667_i86linux32.gz) and add it to your PATH*
	
* [NCBI blast+](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)
	
* [Snippy](https://github.com/tseemann/snippy)
	
* [HMMER](http://hmmer.org/)
	
* Databases folder for agr group typing and variant calling
		
		databases/
			├── agrD_hmm.hmm
			├── agrD_hmm.hmm.h3f
			├── agrD_hmm.hmm.h3i
			├── agrD_hmm.hmm.h3m
			├── agrD_hmm.hmm.h3p
			├── agr_operon_primers.fa
			├── gp1234_motifs_all.fasta
			└── references
				├── gp1-operon_ref.gbk
				├── gp2-operon_ref.gbk
				├── gp3-operon_ref.gbk
				└── gp4-operon_ref.gbk

			
&nbsp;	
---

### USAGE:
	agr_fs_detect.sh <fasta_file> <path_to_databases> [-hv]
	
	* <fasta_file> : S. aureus genome assembly in fasta format. 
	* <path_to_databases>  : Absolute path to database files. Default " ./databases "
	* -h to print this help message
	* -v to print version
&nbsp;
---

### OUTPUTS:

A new directory with suffix -results  will be created

***NOTE:*** **There are 15 possible kmers for each agr group. The analyses will continue even if only one kmer matches a given agr-group but it should be noted that < 5 kmers matching leads to a low confidence agr-group call. Please check fasta-agr_gp.tab for the number of kmers matched.** 

* **fasta-summary.tab:**

		col 1: Filename
		col 2: Agr group (gp1/gp2/gp3/gp4). 'u' means unknown. If multiple agr groups were found (col 5 = m), the displayed agr group is the majority/highest confidence. 
		col 3: Match score for agr group (maximum 15; 0 means untypeable; < 5 means low confidence)
		col 4: Canonical or non-canonical agrD ( 1 means canonical; 0 means non-canonical; u means unknown)
		col 5: If multiple agr groups were found, likely due to multiple S. aureus isolates in sequence ( s means single, m means multiple, u means unknown )
		col 6: Number of frameshifts found in CDS of extracted agr operon ( Column is 'u' if agr operon was not extracted )
		
	*If multiple assemblies are run, use this command from parent directory to output a consolidated summary table for all samples*
	
		cat ./*-results/*-summary.tab > filename.tab
		
* **fasta-agr_gp.tab:** 

		col 1: Assembly Contig ID
		col 2: ID of matched agr group kmer
		col 3: evalue
		col 4: Percentage identity of match
		col 5: Start position of kmer alignment on input sequence
		col 6: End position of kmer alignment on input sequence
	
* **fasta-blastn-log.txt:**

	Standard output of ncbi blastn 
		
* **fasta-agr_operon.fna:**

	Agr operon extracted from in-silico PCR using USEARCH -SEARCH_PCR in fasta format
	
* **fasta-agr_operon_frameshifts.tab**

	Frameshift mutations in extracted agr operon detected by Snippy. An agr-group specific reference sequence is used to call variants. 
	
* **fasta-hmm.tab:**

	Tabular output of [nhmmer](http://hmmer.org/documentation.html)
	This file is present only if the agr group is untypeable. 
		
* **fasta-hmm-log.txt:**

	Standard output of [nhmmer](http://hmmer.org/documentation.html)
	This file is present only if the agr group is untypeable. 
		
* **fasta-agr_operon_frameshifts.tab**

	Standard output of [USEARCH -SEARCH_PCR](https://drive5.com/usearch/manual/cmd_search_pcr.html)
	
* **fasta-snippy_log.txt:**
		
	Standard output of [Snippy](https://github.com/tseemann/snippy)
		
* **fasta-snippy/**
	
	All output files of [Snippy](https://github.com/tseemann/snippy)
