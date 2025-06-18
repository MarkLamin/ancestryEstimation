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
popLabels=$5
rfMixResults=$6

#make return directory if it doesn't exist
mkdir -p $returnDirectory

cd $returnDirectory

module load plink
module load R/4.4.0-openblas-rocky8

#load datasets into desired directory
plink --bfile $referencePanel \
    --biallelic-only strict \
    --snps-only 'just-acgt' \
    --autosome \
    --allow-no-sex \
    --make-bed \
    --out refPanel
    
plink --bfile $studySample \
    --biallelic-only strict \
    --snps-only 'just-acgt' \
    --autosome \
    --allow-no-sex \
    --make-bed \
    --out stuSample
    
#find SNPs that are common between each data set
Rscript $pathToRepo/commonSNP.R $returnDirectory

#filter datasets to only contain common snps
plink --bfile refPanel \
    --extract commonRefSnps.txt \
    --make-bed \
    --out refCommon
    
plink --bfile stuSample \
    --extract commonStuSnps.txt \
    --make-bed \
    --out stuCommon
    
#find SNPs that should be flipped to other strand
Rscript $pathToRepo/snpToFlip.R $returnDirectory

#flip strands on indicated SNPs
plink --bfile refCommon \
    --flip refSnpToFlip.txt \
    --make-bed \
    --out refFlipped
    
plink --bfile stuCommon \
    --flip stuSnpToFlip.txt \
    --make-bed \
    --out stuFlipped
    
#reorder snps so that Allele1 is always A
Rscript $pathToRepo/snpToReOrder.R $returnDirectory

plink --bfile refFlipped \
    --a1-allele refReOrder.txt 2 1 \
    --make-bed \
    --out refReady
    
plink --bfile stuFlipped \
    --a1-allele stuReOrder.txt 2 1 \
    --make-bed \
    --out stuReady
    
#rename SNPs so that the names are consistent between data sets
Rscript $pathToRepo/snpRename.R $returnDirectory

#merge datasets
plink --bfile refReady \
    --bmerge stuReady \
    --make-bed \
    --allow-no-sex \
    --out allData
    
#find non bi allelic SNPs
Rscript $pathToRepo/snpNonBiAllelic.R $returnDirectory

#remove non bi allelic SNPs
#and also remove SNPs with high missingness too
plink --bfile allData \
    --exclude nonBiAllelicSnps.txt \
#    --geno 0.05 \
    --make-bed \
    --out allDataBiAllelic
    
#perform PCA
plink --bfile allDataBiAllelic \
    --pca \
    --out pcaResult

#perform UMAP directly on genotype data
Rscript $pathToRepo/umapOnBigData.R $returnDirectory

#Deleting files not needed anymore

rm allData.*
rm common*Snps.txt
rm nonBiAllelicSnps.txt
rm refCommon.*
rm refFlipped.*
rm refPanel.*
rm refReOrder.txt
rm refSnpToFlip.txt
rm stuCommon.*
rm stuFlipped.*
rm stuReOrder.txt
rm stuSample.*
rm stuSnpToFlip.txt
