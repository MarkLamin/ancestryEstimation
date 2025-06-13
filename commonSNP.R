library(data.table)
library(magrittr)
library(tidyverse)

#set working directory to be user entered
#setwd("/scratch.global/GDCtraining/lamin022/abstractDataCleaning/")
setwd(commandArgs(trailingOnly = TRUE))

#column names for .bim file
bimColNames <-
  c("Chromosome", "SNP", "GD", "BPP", "Allele1", "Allele2")

uniqueSnpIdentifiers <- function(fileName) {
  dt <- fread(fileName, col.names = bimColNames)
  
  # Only keep SNPs on autosomes with standard nucleotides
  dt <- dt[
    Chromosome %in% 1:22 &
      Allele1 %in% c("A", "T", "C", "G") &
      Allele2 %in% c("A", "T", "C", "G")
  ]
  
  # Create allele options
  dt[, alleleOptions := paste0(Allele1, Allele2)]
  
  # Filter out ambiguous SNPs (A/T and C/G)
  dt <- dt[!alleleOptions %in% c("AT", "TA", "CG", "GC")]
  
  # Create allele option groups efficiently
  dt[, alleleOptionsGroup := ifelse(
    alleleOptions %in% c("AC", "CA", "TG", "GT"), "AC", "AG"
  )]
  
  # Create SNP identifier
  dt[, snpIdentifier := paste0("CHR", Chromosome, "BPP", BPP, alleleOptionsGroup)]
  
  # Get unique identifiers (appear exactly once)
  dt[, .N, by = snpIdentifier][N == 1][
    dt, on = "snpIdentifier", nomatch = 0
  ][, .(SNP, snpIdentifier)]
}

refSnpIdentifiers <- uniqueSnpIdentifiers("refPanel.bim")
stuSnpIdentifiers <- uniqueSnpIdentifiers("stuSample.bim")

commonSnpIdentifiers <-
  intersect(refSnpIdentifiers$snpIdentifier,
            stuSnpIdentifiers$snpIdentifier)

refSnpIdentifiers |>
  filter(snpIdentifier %in% commonSnpIdentifiers) |> 
  select(SNP) |> 
  fwrite(file = "commonRefSnps.txt", col.names = FALSE)

stuSnpIdentifiers |>
  filter(snpIdentifier %in% commonSnpIdentifiers) |> 
  select(SNP) |> 
  fwrite(file = "commonStuSnps.txt", col.names = FALSE)