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
    
#create IDs for each SNP
Rscript $pathToRepo/snpCreateNames.R $returnDirectory
    
#find SNPs that are common between each data set
Rscript $pathToRepo/commonSNP.R $returnDirectory

#filter datasets to only contain common snps
plink --bfile refPanel \
    --extract commonRefSnps.txt \
    --allow-no-sex \
    --make-bed \
    --out refCommon
    
plink --bfile stuSample \
    --extract commonStuSnps.txt \
    --allow-no-sex \
    --make-bed \
    --out stuCommon
    
#find SNPs that should be flipped to other strand
Rscript $pathToRepo/snpToFlip.R $returnDirectory

#flip strands on indicated SNPs
plink --bfile refCommon \
    --flip refSnpToFlip.txt \
    --allow-no-sex \
    --make-bed \
    --out refFlipped
    
plink --bfile stuCommon \
    --flip stuSnpToFlip.txt \
    --allow-no-sex \
    --make-bed \
    --out stuFlipped
    
#reorder snps so that Allele1 is always A
Rscript $pathToRepo/snpToReOrder.R $returnDirectory

plink --bfile refFlipped \
    --a1-allele refReOrder.txt 2 1 \
    --allow-no-sex \
    --make-bed \
    --out refReady
    
plink --bfile stuFlipped \
    --a1-allele stuReOrder.txt 2 1 \
    --allow-no-sex \
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
plink --bfile allData \
    --exclude nonBiAllelicSnps.txt \
    --allow-no-sex \
    --make-bed \
    --out allDataBiAllelic
    
plink --bfile refReady \
    --exclude nonBiAllelicSnps.txt \
    --allow-no-sex \
    --make-bed \
    --out refReadyBiAllelic
    
plink --bfile stuReady \
    --exclude nonBiAllelicSnps.txt \
    --allow-no-sex \
    --make-bed \
    --out stuReadyBiAllelic
    
#perform PCA
plink --bfile allDataBiAllelic \
    --allow-no-sex \
    --pca \
    --out pcaResult

#perform UMAP directly on genotype data
Rscript $pathToRepo/umapOnBigData.R $returnDirectory

#copy shiny app template
cp -r $pathToRepo/shinyAppFile $returnDirectory
cp $popLabels $returnDirectory/shinyAppFile/PopLabels.txt
cp $rfMixResults $returnDirectory/shinyAppFile/RFMixResults.csv

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
rm refReady.*
rm stuReady.*
