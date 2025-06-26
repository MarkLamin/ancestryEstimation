library(data.table) |> suppressPackageStartupMessages()
library(magrittr)
library(tidyverse) |> suppressPackageStartupMessages()

setwd(commandArgs(trailingOnly = TRUE))

#column names for .bim file
bimColNames <-
  c("Chromosome", "SNP", "GD", "BPP", "Allele1", "Allele2")

fread("refPanel.bim") %>%
  set_colnames(bimColNames) %>%
  mutate(SNP = paste0("REF", 1:nrow(.))) %>%
  fwrite(
    file = "refPanel.bim",
    sep = "\t",
    col.names = FALSE,
    quote = FALSE
  )

fread("stuSample.bim") %>%
  set_colnames(bimColNames) %>%
  mutate(SNP = paste0("STU", 1:nrow(.))) %>%
  fwrite(
    file = "stuSample.bim",
    sep = "\t",
    col.names = FALSE,
    quote = FALSE
  )