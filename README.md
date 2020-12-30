# AgrVATE
#### **Agr Variant Assessment & Typing Engine**
###### AgrVATE is a tool for rapid identification of *Staphylococcus aureus* *agr* locus type and also reports possible variants in the *agr* operon. 

---

# WORKFLOW:

![AgrVATE Workflow](agrvate_worlflow.png)

AgrVATE accepts a *S. aureus* genome assembly as input and performs a kmer search using an Agr-group specific kmer database to assign the Agr-group. The *agr* operon is then extracted using *in-silico* PCR and variants are called using an Agr-group specific reference operon. 

---

# INSTALLATION:

Please see the [PREREQUISITES](#PREREQUISITES) section for all the tools required to run AgrVATE. For ease of use, I recommended you install AgrVATE using [Conda](https://conda.io/en/latest/).  ***COMING SOON***

	
	conda create -n agrvate -c bioconda agrvate
	conda activate agrvate
	
This will install all necessary dependencies EXCEPT Usearch.  	
Due to Usearch's license, it cannot be provided with the conda installation. Please download and extract usearch11.0.667 from [here](https://www.drive5.com/downloads/usearch11.0.667_i86linux32.gz) and add it to your PATH
	
For example:
	
	
	wget "https://www.drive5.com/downloads/usearch11.0.667_i86linux32.gz"
	
	gunzip usearch11.0.667_i86linux32.gz
	
	cp ./usearch11.0.667_i86linux32 /usr/bin
	

---
	
# PREREQUISITES:

* __[Usearch 32 bit linux](https://drive5.com/usearch/)__  
Robert C. Edgar, Search and clustering orders of magnitude faster than BLAST, Bioinformatics, Volume 26, Issue 19, 1 October 2010, Pages 2460–2461, https://doi.org/10.1093/bioinformatics/btq461
	
* __[NCBI blast+](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)__  
Camacho, C., Coulouris, G., Avagyan, V. et al. BLAST+: architecture and applications. BMC Bioinformatics 10, 421 (2009). https://doi.org/10.1186/1471-2105-10-421
	
* __[Snippy](https://github.com/tseemann/snippy)__  
Seemann T (2015). Snippy: fast bacterial variant calling from NGS reads. https://github.com/tseemann/snippy
	
* __[HMMER](http://hmmer.org/)__  
S.R. Eddy. Biological sequence analysis using profile hidden Markov models. http://hmmer.org/

* __[SeqKit](https://bioinf.shenwei.me/seqkit/)__  
Shen W, Le S, Li Y, Hu F (2016) SeqKit: A Cross-Platform and Ultrafast Toolkit for FASTA/Q File Manipulation. PLoS ONE 11(10): e0163962. https://doi.org/10.1371/journal.pone.0163962
	
* Databases folder for agr group typing and variant calling  
	* __[DREME](http://meme-suite.org/doc/dreme.html)__  
	***DREME is not included with AgrVATE but it was used to build the kmer database for Agr-group typing (```gp1234_motifs_all.fasta```)***  
	Timothy L. Bailey, DREME: motif discovery in transcription factor ChIP-seq data, Bioinformatics, Volume 27, Issue 12, 15 June 2011, Pages 1653–1659, https://doi.org/10.1093/bioinformatics/btr261
	```
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
				
	```
---

# USAGE:

	agr_fs_detect.sh <fasta_file> [-hv]
	
* <fasta_file> : S. aureus genome assembly in fasta format. 
* -h to print help message
* -v to print version
* If the tool was installed through Conda, you do not have to specify the path to the databases folder. However, if you wish to manually specify the path, it can be entered such as:  

	```
	agr_fs_detect.sh <fasta_file> <path_to_databases>
	```	
	
---

# OUTPUTS:

A new directory with suffix -results  will be created

***NOTE:*** **There are 15 possible kmers for each agr group. The analyses will continue even if only one kmer matches a given agr-group but it should be noted that < 5 kmers matching leads to a low confidence agr-group call. Please check fasta-agr_gp.tab for the number of kmers matched.** 

* __**fasta-summary.tab:**__  

		col 1: Filename
		col 2: Agr group (gp1/gp2/gp3/gp4). 'u' means unknown. If multiple agr groups were found (col 5 = m), the displayed agr group is the majority/highest confidence. 
		col 3: Match score for agr group (maximum 15; 0 means untypeable; < 5 means low confidence)
		col 4: Canonical or non-canonical agrD ( 1 means canonical; 0 means non-canonical; u means unknown)
		col 5: If multiple agr groups were found, likely due to multiple S. aureus isolates in sequence ( s means single, m means multiple, u means unknown )
		col 6: Number of frameshifts found in CDS of extracted agr operon ( Column is 'u' if agr operon was not extracted )
		
	*If multiple assemblies are run, use this command from parent directory to output a consolidated summary table for all samples*
	
		cat ./*-results/*-summary.tab > filename.tab
		
* __**fasta-agr_gp.tab:**__  

		col 1: Assembly Contig ID
		col 2: ID of matched agr group kmer
		col 3: evalue
		col 4: Percentage identity of match
		col 5: Start position of kmer alignment on input sequence
		col 6: End position of kmer alignment on input sequence

* __**fasta-agr_operon_frameshifts.tab:**__  
	Frameshift mutations in CDS of extracted agr operon detected by Snippy. An agr-group specific reference sequence is used to call variants. 
	
		col 1: Filename
		col 2: Position on agr operon compared to reference
		col 3: Type of frameshift
		col 4: Effect of mutation
		col 5: Gene
		
* __**fasta-blastn-log.txt:**__  
	Standard output of ncbi blastn 
		
* __**fasta-agr_operon.fna:**__  
	Agr operon extracted from in-silico PCR using USEARCH -SEARCH_PCR in fasta format
	
* __**fasta-hmm.tab:**__  
	Tabular output of [nhmmer](http://hmmer.org/documentation.html)
	This file is present only if the agr group is untypeable. 
		
* __**fasta-hmm-log.txt:**__  
	Standard output of [nhmmer](http://hmmer.org/documentation.html)
	This file is present only if the agr group is untypeable. 
		
* __**fasta-pcr-log.tab:**__  
	Standard output of [USEARCH -SEARCH_PCR](https://drive5.com/usearch/manual/cmd_search_pcr.html)
	
* __**fasta-snippy_log.txt:**__  
	Standard output of [Snippy](https://github.com/tseemann/snippy)
		
* __**fasta-snippy/**__  
	All output files of [Snippy](https://github.com/tseemann/snippy)
	
# Author 

* Vishnu Raghuram

