REF=/home/jin0008/db/refs/b37/human_g1k_v37_decoy.fasta
INTERVAL=/home/jin0008/db/refs/interval_list/IDT_exome/xgen_exome.b37.interval_list
#define sample name
SAMPLE=IR_SH_0001_S15_L001
F1=${SAMPLE}_R1_001.fastq.gz
F2=${SAMPLE}_R2_001.fastq.gz

#BWA-MEM
bwa mem -M -t 16 $REF $F1 $F2 > mapped.bam

#FastqtoSam
gatk --java-options "-Xmx32G" FastqToSam \
-F1 $F1 \
-F2 $F2 \
-O unmapped.bam \
-R $REF \
-PL illumina \
-SM ${SAMPLE} \
-RG ${SAMPLE}

#MergeBamAlignment
gatk --java-options "-Xmx32G" MergeBamAlignment \
--VALIDATION_STRINGENCY SILENT \
--EXPECTED_ORIENTATIONS FR \
--ATTRIBUTES_TO_RETAIN X0 \
--ALIGNED_BAM mapped.bam \
--UNMAPPED_BAM unmapped.bam \
-O input.bam \
--REFERENCE_SEQUENCE $REF \
-SO unsorted \
--IS_BISULFITE_SEQUENCE false \
--ALIGNED_READS_ONLY false \
--CLIP_ADAPTERS false \
--MAX_RECORDS_IN_RAM 2000000 \
--ADD_MATE_CIGAR true \
--MAX_INSERTIONS_OR_DELETIONS -1 \
--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
--UNMAPPED_READ_STRATEGY COPY_TO_TAG \
--ALIGNER_PROPER_PAIR_FLAGS true \
--UNMAP_CONTAMINANT_READS true

#SortSam
gatk --java-options "-Xmx32G" SortSam \
--INPUT input.bam \
--OUTPUT sort.bam \
--SORT_ORDER "coordinate" \
--CREATE_INDEX false \
--CREATE_MD5_FILE false \
-R $REF

#SetNmMdAndUqTags
gatk --java-options "-Xmx32G" SetNmMdAndUqTags \
--INPUT sort.bam \
--OUTPUT sort_fixed.bam \
-R $REF \
--CREATE_INDEX true \
--CREATE_MD5_FILE true 

#MarkDuplicates
gatk --java-options "-Xmx32G" MarkDuplicates \
--INPUT sort_fixed.bam \
--OUTPUT markduplicated.bam \
--METRICS_FILE metrics_profile \
-R $REF 

#AddorReplaceReadgroup
gatk --java-options "-Xmx32G" AddOrReplaceReadGroups \
--INPUT markduplicated.bam \
--OUTPUT RGfixed.bam \
-LB {SAMPLE} \
-PL illumina \
-PU Novaseq6000 \
-SM {SAMPLE}

samtools index RGfixed.bam

#BaseRecalibrator
gatk --java-options "-Xmx32G" BaseRecalibrator \
-R $REF \
-I RGfixed.bam \
--use-original-qualities \
-O recal_data.table \
--known-sites /home/jin0008/db/refs/b37/dbsnp_138.b37.vcf \
--known-sites /home/jin0008/db/refs/b37/Mills_and_1000G_gold_standard.indels.b37.vcf \
--known-sites /home/jin0008/db/refs/b37/1000G_phase1.indels.b37.vcf \
-L $INTERVAL

#BQSR
gatk --java-options "-Xmx32G" ApplyBQSR \
-R $REF \
-I RGfixed.bam \
-O analysisready.bam \
-L $INTERVAL \
-bqsr recal_data.table \
--add-output-sam-program-record \
--create-output-bam-md5 \
--use-original-qualities
