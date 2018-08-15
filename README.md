# IRD
This repository is made for processing Next-Generation Sequencing data in Korean with inherited retinal diseases.

The repository consisted of two main sequencing strategy.
1) whole exome sequencing
2) whole genome sequencing

Each part has three components.
a. SNPs + Indel
b. CNV (copy number variations)
c. SV (structural variations)

Whole exome sequencing was done with IDT xGen Exome Research Panel V1.0 with NovaSeq 6000.
Whole genome sequencing was done with PCR-free protocol.

#This repository was created for shared bioinformatic code in WES & WGS data analysis
#Reference genome
1. hg38
2. hg19 (b37 or b37 + decoy)

#SNP+Indels
- current industry standard GATK 4.0.x

#Copy Number variation analysis tools (Read depth based)
1. Whole genome sequencing
 a. CNVnator (https://github.com/abyzovlab/CNVnator)
 b. ERDS (http://www.utahresearch.org/mingfuzhu/erds/)

2. Whole exome sequencing
 a. XHMM (http://atgu.mgh.harvard.edu/xhmm/tutorial.shtml)
 b. CoNIFER (http://conifer.sourceforge.net)
 
#Structural variation analysis tools (split read based)
1. Whole genome or exome sequencing (both)
 a. Manta (https://github.com/Illumina/manta)
 b. Delly (https://github.com/dellytools/delly)
 c. Pindel
