#for reading genotype data
library(KRIS)

#for data wrangling
library(data.table)
library(magrittr)
library(tidyverse)

#for dimensional reduction
library(uwot)

#for imputation
library(missMethods)

setwd(commandArgs(trailingOnly = TRUE))

read.bed(bed = "allDataBiAllelic.bed",
         bim = "allDataBiAllelic.bim",
         fam = "allDataBiAllelic.fam") |>
  with(snp) |>
  impute_mean() |>
  scale() |>
  uwot::umap(n_threads = 4) |>
  fwrite(file = "bigUmapResults.csv",
         row.names = TRUE)