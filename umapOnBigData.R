#for reading genotype data
library(KRIS) |> suppressPackageStartupMessages()

#for data wrangling
library(data.table) |> suppressPackageStartupMessages()
library(magrittr)
library(tidyverse) |> suppressPackageStartupMessages()

#for dimensional reduction
library(uwot) |> suppressPackageStartupMessages()

#for imputation
library(missMethods) |> suppressPackageStartupMessages()

setwd(commandArgs(trailingOnly = TRUE))

bedObject <- read.bed(bed = "allDataBiAllelic.bed",
                      bim = "allDataBiAllelic.bim",
                      fam = "allDataBiAllelic.fam")

dimensionSize <- 2

bedObject |>
  with(snp) |>
  set_rownames(bedObject$ind.info$IndID) |>
  impute_mean() |>
  scale() |>
  uwot::umap(n_threads = 10,
             n_components = dimensionSize,
             n_neighbors = 30) |>
  set_colnames(paste0("UMAP", 1:dimensionSize)) |>
  fwrite(file = "bigUmapResults.csv",
         row.names = TRUE)