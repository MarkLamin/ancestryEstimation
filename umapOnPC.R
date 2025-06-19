library(uwot)
library(data.table) |> suppressPackageStartupMessages()
library(magrittr)
library(tidyverse) |> suppressPackageStartupMessages()

setwd(commandArgs(trailingOnly = TRUE))

eigvenVectorFilePath <- "pcaResult.eigenvec"

fread(eigvenVectorFilePath) |>
  select(-V1) |>
  column_to_rownames("V2") |>
  set_colnames(paste("PC", 1:20, sep = "")) |>
  scale() |>
  uwot::umap(n_threads = 30) |>
  #with(layout) |>
  set_colnames(paste("UMAP", 1:2, sep = "")) |>
  fwrite(file = "umapOnPC.csv",
         row.names = TRUE)
