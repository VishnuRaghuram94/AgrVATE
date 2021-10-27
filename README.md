# AgrVATE
#### **Agr Variant Assessment & Typing Engine**
###### AgrVATE is a tool for rapid identification of *Staphylococcus aureus* *agr* locus type and also reports possible variants in the *agr* operon. 

---

# WORKFLOW:

![AgrVATE Workflow](https://github.com/VishnuRaghuram94/agr_fs_detection/blob/main/agrvate_workflow.png)

AgrVATE accepts a *S. aureus* genome assembly as input and performs a kmer search using an Agr-group specific kmer database to assign the Agr-group. The *agr* operon is then extracted using *in-silico* PCR and variants are called using an Agr-group specific reference operon. 

---

# INSTALLATION:

Please see the [PREREQUISITES](#PREREQUISITES) section for all the tools required to run AgrVATE. For ease of use, I recommended you install AgrVATE using [Conda](https://conda.io/en/latest/).

	
	conda create -n agrvate -c bioconda agrvate
	conda activate agrvate
	
This will install all necessary dependencies EXCEPT Usearch.  	
Due to Usearch's license, it cannot be provided with the conda installation. Please download and extract usearch11.0.667 (osx32 or linux32) from [here](https://www.drive5.com/downloads/) and add it to your PATH
	
For example (Use the version appropriate for your operating system):
	
	
	curl "https://www.drive5.com/downloads/usearch11.0.667_i86linux32.gz" --output usearch11.0.667_i86linux32.gz #Downloads usearch binary
	
	gunzip usearch11.0.667_i86linux32.gz #Decompresses usearch binary
	
	chmod 755 usearch11.0.667_i86linux32 #Changes permissions to executable
	
	cp ./usearch11.0.667_i86linux32 $(dirname "$(which agrvate)") #Copies usearch binary to the same directory as agrvate 

***NOTE:*** Currently, only the 32-bit version of usearch is free to use. This version is not supported by WSL or MacOS (post-Catalina). Therefore, it is recommended to use AgrVATE on Linux machines or older versions MacOS. If you are unable to run usearch, use the ```-m``` option to run MUMmer instead (IN BETA). However, please note that if there are large insertions/deletions in the agr-operon, MUMmer can split the alignment into 2 and the resulting extracted agr-operon will not be intact, in which case frameshift detection using snippy may miss these indels.	

---
	
# PREREQUISITES:

* __[Usearch 32 bit linux](https://drive5.com/usearch/)__  
Robert C. Edgar, Search and clustering orders of magnitude faster than BLAST, Bioinformatics, Volume 26, Issue 19, 1 October 2010, Pages 2460–2461, https://doi.org/10.1093/bioinformatics/btq461
	
* __[NCBI blast+](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)__  
Camacho, C., Coulouris, G., Avagyan, V. et al. BLAST+: architecture and applications. BMC Bioinformatics 10, 421 (2009). https://doi.org/10.1186/1471-2105-10-421
	
* __[Snippy](https://github.com/tseemann/snippy)__  
Seemann T (2015). Snippy: fast bacterial variant calling from NGS reads. https://github.com/tseemann/snippy

* __[MUMmer](https://github.com/garviz/MUMmer)__  
S. Kurtz. et al (2004). Versatile and open software for comparing large genomes. Genome Biology, R12. https://doi.org/10.1186/gb-2004-5-2-r12
	
* __[HMMER](http://hmmer.org/)__  
S.R. Eddy. Biological sequence analysis using profile hidden Markov models. http://hmmer.org/

* __[SeqKit](https://bioinf.shenwei.me/seqkit/)__  
Shen W, Le S, Li Y, Hu F (2016) SeqKit: A Cross-Platform and Ultrafast Toolkit for FASTA/Q File Manipulation. PLoS ONE 11(10): e0163962. https://doi.org/10.1371/journal.pone.0163962
	
* Databases folder for agr group typing and variant calling  
	* __[DREME](http://meme-suite.org/doc/dreme.html)__  
	***DREME is not required for AgrVATE but it was used to build the kmer database for Agr-group typing*** (```gp1234_motifs_all.fasta```)    
	Timothy L. Bailey, DREME: motif discovery in transcription factor ChIP-seq data, Bioinformatics, Volume 27, Issue 12, 15 June 2011, Pages 1653–1659, https://doi.org/10.1093/bioinformatics/btr261
	```
	agrvate_databases/
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
			└── mummer_ref_operon.fna	
	```
---

# USAGE:

	agrvate -i filename.fasta [options]
	
* FLAGS:  
	* ```-i```&nbsp;&nbsp;&nbsp;Input S. aureus genome in FASTA format [alternate: ```--input```]
	* ```-t```&nbsp;&nbsp;&nbsp;Does agr typing only (skips agr operon extraction and frameshift detection) [alternate: ```--typing-only```]
	* ```-m```&nbsp;&nbsp;&nbsp;Uses MUMmer dnadiff instead of usearch [alternate: ```--mummer```]
	* ```-f```&nbsp;&nbsp;&nbsp;Force overwrite existing results directory [alternate: ```--force```]
	* ```-d```&nbsp;&nbsp;&nbsp;Path to agrvate_databases (Not required if installed using Conda) [alternate: ```--databases```]
	* ```-h```&nbsp;&nbsp;&nbsp;Print this help message and exit [alternate: ```--help```]
	* ```-v```&nbsp;&nbsp;&nbsp;Print version and exit [alternate: ```--version```]

*AgrVATE supports a single FASTA file as input, but the file can be a multi-fasta file. To run multiple *S. aureus* genomes, it is recommended to keep them as separate files in a common directory.*  
*For example*:

	ls fasta_files/* | xargs -I {} agrvate -i {} [options]
	
---

# OUTPUTS:

### RESULTS: 
		
A new directory with suffix ```-results```  will be created where all the following files can be found

***NOTE:*** **There are 15 possible kmers for each agr group per genome. The analyses will continue even if only one kmer matches a given agr-group but it should be noted that < 5 kmers matching leads to a low confidence agr-group call. Col 3 in ```fasta-summary.tab``` shows the number of kmers matched** 

* __**fasta-summary.tab:**__  

		col 1: Filename
		col 2: Agr group (gp1/gp2/gp3/gp4). 'u' means unknown. If multiple agr groups were found (col 5 = m), the displayed agr group is the majority/highest confidence. 
		col 3: Match score for agr group (maximum 15; 0 means untypeable; < 5 means low confidence)
		col 4: Canonical or non-canonical agrD ( 1 means canonical; 0 means non-canonical; u means unknown)
		col 5: If multiple agr groups were found, likely due to multiple S. aureus isolates in sequence ( s means single, m means multiple, u means unknown )
		col 6: Number of frameshifts found in CDS of extracted agr operon ( Column is 'u' if agr operon was not extracted )
		
	*If multiple assemblies are run, use this command from parent directory to output a consolidated summary table for all samples*
	
		awk 'FNR==1 && NR!=1 { while (/^#/) getline; } 1 {print}' ./*-results/*-summary.tab > filename.tab
		
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
	
* __**fasta-mummer_log.txt:**__  
	Standard output of [MUMmer dnadiff](https://github.com/garviz/MUMmer)
		
* __**fasta-mummer/**__  
	All output files of [MUMmer dnadiff](https://github.com/garviz/MUMmer)	

### TROUBLESHOOTING	

An error report summary file with suffix ```-error-report.tab``` will be created in the working directory.  

**The error report file does not contain any results. It merely shows which steps of the process pipeline ran (```pass```) and which steps did not (```fail```).**   

* ```pass``` Does not necessarily mean a result was obtained, it only means the step completed successfully. 
* ```fail``` Does not necessarily mean there was an error, it only means that step was not performed. However, possible causes of error for each column are mentioned below.
 
The columns are ordered by how the processes are carried out. i.e col 1 is the first step and col 7 is the last. If one column shows ```fail``` it means the programme exited at that step and therefore the remaining columns will also show ```fail``` . 

* __**error-report.tab:**__  

		col 1: Input name - the argument supplied to the -i flag
		col 2: Input check - If fail, the input did not pass the valid fasta file criteria
		col 3: Databases check - If fail, the databases folder or the path to the databases was not valid. 
		col 4: Outdir check - If fail, the results directory already exists and couldn't be overwritten. Use flag -f or --force. 
		col 5: Agr typing - If fail, the Agr typing kmer search could not be performed. Check if blastn is installed correctly. 
		col 6: Operon check - If fail, in-silico PCR was not performed by usearch or agr operon search was not performed by mummer. Check if usearch/mummer is installed correctly. 
		col 7: Snippy check - If fail, agr operon frameshift detection was not performed. Check if snippy is installed correctly.

	*If multiple assemblies are run, use this command from parent directory to output a consolidated report table for all samples*
	
		awk 'FNR==1 && NR!=1 { while (/^#/) getline; } 1 {print}' ./*-error-report.tab > filename.tab

# Citation 

Please cite the following preprint if you use AgrVATE in your research. Thank you!

Raghuram V, Alexander AM, Loo HQ, Petit III RA, Goldberg JB, Read TD, *Species-wide phylogenomics of the Staphylococcus aureus agr operon reveals convergent evolution of frameshift mutations.* **Biorxiv**. (2021), https://doi.org/10.1101/2021.07.29.454156

# Author 

* Vishnu Raghuram

