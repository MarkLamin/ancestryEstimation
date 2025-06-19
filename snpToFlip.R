library(data.table)
library(magrittr)
library(tidyverse, warn.conflicts = FALSE)

#set working directory to be user entered
#setwd("/scratch.global/GDCtraining/lamin022/abstractDataCleaning/")
setwd(commandArgs(trailingOnly = TRUE))

#column names for .bim file
bimColNames <-
  c("Chromosome", "SNP", "GD", "BPP", "Allele1", "Allele2")

fread("refCommon.bim") |> 
  set_colnames(bimColNames) |> 
  filter(Allele1 != "A", Allele2 != "A") |> 
  select(SNP) |> 
  fwrite(file = "refSnpToFlip.txt", col.names = FALSE)

fread("stuCommon.bim") |> 
  set_colnames(bimColNames) |> 
  filter(Allele1 != "A", Allele2 != "A") |> 
  select(SNP) |> 
  fwrite(file = "stuSnpToFlip.txt", col.names = FALSE)
