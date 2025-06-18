#!/bin/bash
#SBATCH --time=8:00:00
#SBATCH --job-name=harmonizationPipeline
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=200g
#SBATCH --mail-type=ALL
#SBATCH --mail-user=
#SBATCH --output=harmonizationPipeline.out
#SBATCH --error=harmonizationPipeline.err

referencePanel=$1
studySample=$2
returnDirectory=$3
pathToRepo=$4

#make return directory if it doesn't exist
mkdir -p $returnDirectory

cd /scratch.global/GDCtraining/lamin022/abstractDataCleaning
module load plink
module load R/4.4.0-openblas-rocky8

#load datasets into desired directory
plink --bfile $referencePanel \
    --biallelic-only strict \
    --snps-only 'just-acgt' \
    --autosome \
    --allow-no-sex \
    --make-bed \
    --out $returnDirectory/refPanel
    
plink --bfile $studySample \
    --biallelic-only strict \
    --snps-only 'just-acgt' \
    --autosome \
    --allow-no-sex \
    --make-bed \
    --out $returnDirectory/stuSample
    
#find SNPs that are common between each data set
Rscript $pathToRepo/commonSNP.R $returnDirectory

#filter datasets to only contain common snps
plink --bfile $returnDirectory/refPanel \
    --extract $returnDirectory/commonRefSnps.txt \
    --make-bed \
    --out $returnDirectory/refCommon
    
plink --bfile $returnDirectory/stuSample \
    --extract $returnDirectory/commonStuSnps.txt \
    --make-bed \
    --out $returnDirectory/stuCommon
    
#find SNPs that should be flipped to other strand
Rscript $pathToRepo/snpToFlip.R $returnDirectory

#flip strands on indicated SNPs
plink --bfile $returnDirectory/refCommon \
    --flip $returnDirectory/refSnpToFlip.txt \
    --make-bed \
    --out $returnDirectory/refFlipped
    
plink --bfile $returnDirectory/stuCommon \
    --flip $returnDirectory/stuSnpToFlip.txt \
    --make-bed \
    --out $returnDirectory/stuFlipped
    
#reorder snps so that Allele1 is always A
Rscript $pathToRepo/snpToReOrder.R $returnDirectory

plink --bfile $returnDirectory/refFlipped \
    --a1-allele $returnDirectory/refReOrder.txt 2 1 \
    --make-bed \
    --out $returnDirectory/refReady
    
plink --bfile $returnDirectory/stuFlipped \
    --a1-allele $returnDirectory/stuReOrder.txt 2 1 \
    --make-bed \
    --out $returnDirectory/stuReady
    
#rename SNPs so that the names are consistent between data sets
Rscript $pathToRepo/snpRename.R $returnDirectory

#merge datasets
plink --bfile $returnDirectory/refReady \
    --bmerge $returnDirectory/stuReady \
    --make-bed \
    --allow-no-sex \
    --out $returnDirectory/allData
    
#find non bi allelic SNPs
Rscript $pathToRepo/snpNonBiAllelic.R $returnDirectory

#remove non bi allelic SNPs
#and also remove SNPs with high missingness too
plink --bfile $returnDirectory/allData \
    --exclude $returnDirectory/nonBiAllelicSnps.txt \
#    --geno 0.05 \
    --make-bed \
    --out $returnDirectory/allDataBiAllelic
    
#perform PCA
plink --bfile $returnDirectory/allDataBiAllelic \
    --pca \
    --out $returnDirectory/pcaResult

#perform UMAP directly on genotype data
Rscript $pathToRepo/umapOnBigData.R $returnDirectory
