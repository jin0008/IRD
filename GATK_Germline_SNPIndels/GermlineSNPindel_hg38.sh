REF=/home/jin0008/db/refs/hg38/resources_broad_hg38_v0_Homo_sapiens_assembly38.fasta
INTERVAL=/home/jin0008/db/refs/interval_list/IDT_exome/xgen_exome.hg38.interval_list


#Haplotypecaller
gatk --java-options "-Xmx32g" HaplotypeCaller \
-R $REF \
-I analysisready.bam \
-O Haplotypecaller.vcf \
-bamout bamout.bam \
-ERC GVCF \
-L $INTERVAL \
-D /home/jin0008/db/refs/hg38/resources_broad_hg38_v0_Homo_sapiens_assembly38.dbsnp138.vcf

#combine GVCF
#Samples more than > 30 exomes or 1 WGS to run VQSR
gatk --java-options "-Xmx16g" CombineGVCFs \
-R $REF \
-V {SAMPLE1}.vcf \
-V {SAMPLE2}.vcf \
-O combine.gvcf.vcf \
-L $INTERVAL \
-D /home/jin0008/db/refs/hg38/resources_broad_hg38_v0_Homo_sapiens_assembly38.dbsnp138.vcf

##GenotypeGVCFs
gatk --java-options "-Xmx120G" GenotypeGVCFs \
-R $REF \
-V combine.gvcf.vcf \
-O final_variants.vcf \
-D /home/jin0008/db/refs/hg38/resources_broad_hg38_v0_Homo_sapiens_assembly38.dbsnp138.vcf

#Variant recalibrator (Indel)
gatk --java-options "-Xmx24g" VariantRecalibrator \
-R $REF \
-V final_variants.vcf \
--max-gaussians 4 \
--resource mills,known=false,training=true,truth=true,prior=12.0:/home/jin0008/db/refs/hg38/resources_broad_hg38_v0_Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
--resource axiomPoly,known=false,training=true,truth=false,prior=10.0:/home/jin0008/db/refs/hg38/resources_broad_hg38_v0_Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf.gz \
--resource dbsnp,known=true,training=false,truth=false,prior=2.0:/home/jin0008/db/refs/hg38/resources_broad_hg38_v0_Homo_sapiens_assembly38.dbsnp138.vcf \
-an FS -an QD -an SOR \
-mode INDEL \
--trust-all-polymorphic \
-O raw.indel.recal \
--tranches-file raw.indel.tranches \
--rscript-file recal_indel.plots.R

#Variant recalibrator (SNP)
gatk --java-options "-Xmx120G" VariantRecalibrator \
-R $REF \
-V final_variants.vcf \
--resource hapmap,known=false,training=true,truth=true,prior=15.0:/home/jin0008/db/refs/hg38/resources_broad_hg38_v0_hapmap_3.3.hg38.vcf.gz \
--resource omni,known=false,training=true,truth=false,prior=12.0:/home/jin0008/db/refs/hg38/resources_broad_hg38_v0_1000G_omni2.5.hg38.vcf.gz \
--resource 1000G,known=false,training=true,truth=false,prior=10.0:/home/jin0008/db/refs/hg38/resources_broad_hg38_v0_1000G_phase1.snps.high_confidence.hg38.vcf.gz \
--resource dbsnp,known=true,training=false,truth=false,prior=2.0:/home/jin0008/db/refs/hg38/resources_broad_hg38_v0_Homo_sapiens_assembly38.dbsnp138.vcf \
-an QD -an FS -an MQ -an SOR \
-mode SNP \
--max-gaussians 6 \
--trust-all-polymorphic \
-O raw.SNPs.recal \
--tranches-file raw.SNPs.tranches \
--rscript-file recal_SNP.plots.R

#ApplyVQSR (Indel)
gatk --java-options "-Xmx120G" ApplyVQSR \
-R $REF \
-V final_variants.vcf \
--mode INDEL \
--recal-file raw.indel.recal \
--tranches-file raw.indel.tranches \
-O recal_indel.vcf \
-ts-filter-level 99.0

#ApplyVQSR (SNP)
gatk --java-options "-Xmx120G" ApplyVQSR \
-R $REF \
-V recal_indel.vcf \
--mode SNP \
--recal-file raw.SNPs.recal \
--tranches-file raw.SNPs.tranches \
-O recal_SNP_indel.vcf \
-ts-filter-level 99.0

#CalculateGenotypePosteriors
gatk --java-options "-Xmx120G" CalculateGenotypePosteriors \
-R $REF \
-V recal_SNP_indel.vcf \
-supporting /home/jin0008/db/refs/hg38/dbsnp_146.hg38.vcf.gz \
-O output.1000G_PP.vcf.gz

#VariantFiltration 
gatk --java-options "-Xmx120G" VariantFiltration \
-R $REF \
-V output.1000G_PP.vcf.gz \
--filter-expression "GQ<20 || QD < 2.0 || FS >60.0 || MQ < 40.0 || SOR > 3.0  || QUAL < 3.0" \
--filter-name "basic_filters" \
-O variant_filtration.vcf.gz

#SelectVariants
gatk --java-options "-Xmx120G" SelectVariants \
-R $REF \
-V variant_filtration.vcf.gz \
-sn ${SAMPLE} \
--exclude-non-variants \
-O ${SAMPLE}.vcf.gz
