#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(coloc))

option_list <- list(
  make_option(c("--lbf1"), type="character", default=NULL,
              help="file with LBFs and minimum other columns: region (fixed), trait (arg), variant (arg)", metavar = "type"),
  make_option(c("--lbf2"), type="character", default=NULL,
              help="file with LBFs and minimum other columns: region (fixed), dataset (arg), trait (arg), variant (arg)", metavar = "type"),
  make_option(c("--lbf1_trait_col"), type="character", default=NULL,
              help="trait column name in the lbf1 file", metavar = "type"),
  make_option(c("--lbf1_variant_col"), type="character", default=NULL,
              help="variant column name in the lbf1 file", metavar = "type"),
  make_option(c("--lbf2_dataset_col"), type="character", default=NULL,
              help="dataset column name in the lbf2 file", metavar = "type"),
  make_option(c("--lbf2_trait_col"), type="character", default=NULL,
              help="trait column name in the lbf2 file", metavar = "type"),
  make_option(c("--lbf2_variant_col"), type="character", default=NULL,
              help="variant column name in the lbf2 file", metavar = "type"),
  make_option(c("--num_lbf_vars"), type="integer", default=10,
              help="number of LBF variables to use", metavar = "type"),
  make_option(c("--prior_p1"), type="double", default=1e-4,
              help="prior probability a SNP is associated with trait 1", metavar = "type"),
  make_option(c("--prior_p2"), type="double", default=1e-4,
              help="prior probability a SNP is associated with trait 2", metavar = "type"),
  make_option(c("--prior_p12"), type="double", default=5e-6,
              help="prior probability a SNP is associated with both traits", metavar = "type")
  )

opt <- parse_args(OptionParser(option_list=option_list))

lbf1 <- fread(opt$lbf1)
lbf2 <- fread(opt$lbf2)

for (trait1 in unique(lbf1[[opt$lbf1_trait_col]])) {
  trait1_table <- lbf1 %>% filter(get(opt$lbf1_trait_col) == trait1)
  n_regions <- length(unique(trait1_table$region))
  if (n_regions != 1) {
    message(paste0(opt$lbf1, " ", trait1, ": more than 1 region: ", n_regions, " - running all regions separately"))
  }
  for (region in unique(trait1_table$region)) {
    trait1_table <- trait1_table %>% filter(region==region)
    region1 <- unlist(unlist(strsplit(region, ":|-|_"))[-1] %>% map(as.numeric))
    region1_length <- region1[2] - max(region1[1], 0)

    lbf1_for_coloc <- t(as.matrix(trait1_table %>% select(paste0("lbf_variable",1:opt$num_lbf_vars))))
    colnames(lbf1_for_coloc) <- trait1_table[[opt$lbf1_variant_col]]

    for (trait2 in unique(lbf2[[opt$lbf2_trait_col]])) {
      trait2_table <- lbf2 %>% filter(get(opt$lbf2_trait_col) == trait2)
      n_regions <- length(unique(trait2_table$region))
      if (n_regions != 1) {
        message(paste0(opt$lbf2, " ", trait2, ": more than 1 region: ", n_regions, " - this shouldn't happen - quitting"))
        quit(status=1)
      }
      region2 <- unlist(unlist(strsplit(trait2_table[1]$region, ":|-|_"))[-1] %>% map(as.numeric))
      region2_length <- region2[2] - max(region2[1], 0)

      overlap <- max(0, min(region1[2], region2[2]) - max(region1[1], region2[1]))
      overlap_prop <- overlap / min(region1_length, region2_length)
      
      lbf2_for_coloc <- t(as.matrix(trait2_table %>% select(paste0("lbf_variable",1:opt$num_lbf_vars))))
      colnames(lbf2_for_coloc) <- trait2_table[[opt$lbf2_variant_col]]

      coloc_results <- coloc.bf_bf(lbf1_for_coloc, lbf2_for_coloc, p1=opt$prior_p1, p2=opt$prior_p2, p12=opt$prior_p12)$summary

      if (!is.null(coloc_results)){
        coloc_results <- coloc_results %>% add_column(
          "#trait1"=rep(trait1, nrow(coloc_results)),
          dataset=rep(trait2_table[1][[opt$lbf2_dataset_col]], nrow(coloc_results)),
          trait2=rep(trait2, nrow(coloc_results)),
          region1=rep(trait1_table[1]$region, nrow(coloc_results)),
          region2=rep(trait2_table[1]$region, nrow(coloc_results)),
          overlap_prop=rep(overlap_prop, nrow(coloc_results)),
          .before="nsnps")
        cat(format_tsv(coloc_results))
      }
    }
  }
}
