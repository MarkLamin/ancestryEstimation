library(data.table) |> suppressPackageStartupMessages()
library(magrittr)
library(tidyverse) |> suppressPackageStartupMessages()

#set working directory to be user entered
#setwd("/scratch.global/GDCtraining/lamin022/abstractDataCleaning/")
setwd(commandArgs(trailingOnly = TRUE))

#column names for .bim file
bimColNames <-
  c("Chromosome", "SNP", "GD", "BPP", "Allele1", "Allele2")

fread("allData.bim") |>
  set_colnames(bimColNames) |>
  group_by(Chromosome, BPP) |>
  filter(n() > 1) |>
  ungroup() |>
  select(SNP) |>
  fwrite(file = "nonBiAllelicSnps.txt", col.names = FALSE)
