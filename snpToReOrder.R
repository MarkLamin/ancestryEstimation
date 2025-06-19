library(data.table)
library(magrittr)
library(tidyverse, warn.conflicts = FALSE)

#set working directory to be user entered
#setwd("/scratch.global/GDCtraining/lamin022/abstractDataCleaning/")
setwd(commandArgs(trailingOnly = TRUE))

#column names for .bim file
bimColNames <-
  c("Chromosome", "SNP", "GD", "BPP", "Allele1", "Allele2")

fread("refFlipped.bim") |>
  set_colnames(bimColNames) |>
  select(SNP) |>
  mutate(AlleleOfInterest = "A") |>
  fwrite(file = "refReOrder.txt",
         col.names = FALSE,
         sep = "\t")

fread("stuFlipped.bim") |>
  set_colnames(bimColNames) |>
  select(SNP) |>
  mutate(AlleleOfInterest = "A") |>
  fwrite(file = "stuReOrder.txt",
         col.names = FALSE,
         sep = "\t")