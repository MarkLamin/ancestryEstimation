library(data.table) |> suppressPackageStartupMessages()
library(magrittr)
library(tidyverse) |> suppressPackageStartupMessages()

#set working directory to be user entered
#setwd("/scratch.global/GDCtraining/lamin022/abstractDataCleaning/")
setwd(commandArgs(trailingOnly = TRUE))

#column names for .bim file
bimColNames <-
  c("Chromosome", "SNP", "GD", "BPP", "Allele1", "Allele2")

fread("refReady.bim") |> 
  set_colnames(bimColNames) |> 
  mutate(SNP = paste0("CHR", Chromosome, "BPP", BPP, Allele2)) |> 
  fwrite(file = "refReady.bim",
         sep = "\t",
         col.names = FALSE,
         quote = FALSE)

fread("stuReady.bim") |> 
  set_colnames(bimColNames) |> 
  mutate(SNP = paste0("CHR", Chromosome, "BPP", BPP, Allele2)) |> 
  fwrite(file = "stuReady.bim",
         sep = "\t",
         col.names = FALSE,
         quote = FALSE)
