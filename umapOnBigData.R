#for reading genotype data
library(KRIS)

#for data wrangling
library(data.table) |> suppressPackageStartupMessages()
library(magrittr)
library(tidyverse) |> suppressPackageStartupMessages()

#for dimensional reduction
library(uwot) |> suppressPackageStartupMessages()

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