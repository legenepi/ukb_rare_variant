#!/usr/bin/env Rscript

GENO_BASE <- "/Bulk/Genotype Results/Genotype calls/ukb22418_c*"

'Usage:
  make_inputs_regenie_step1.R [--project STRING] --pheno FILE --covar FILE --covarColList STRING --catCovarList STRING (--bt | --qt) --out FILE

Options:
  --project STRING      RAP project ID (default: current project)
  --pheno FILE          phenotype file 
  --covar FILE          covariate file
  --covarColList STRING,..,STRING
                        comma separated list of covariate names to 
                        keep (can use parameter expansion {i:j})
  --catCovarList STRING,..,STRING
                        comma separated list of categorical 
                        covariates
  --bt                  Binary trait
  --qt                  Quantitative trait
  --out FILE            output JSON file
' -> doc

suppressMessages(library(docopt))
suppressMessages(library(tidyverse))
suppressMessages(library(jsonlite))
source("make_inputs_functions.R")

args <- docopt(doc)

inputs <- list("regenie_step1.genos" = get_genos(GENO_BASE, args$project),
               "regenie_step1.pheno" = get_file_id(args$pheno, args$project),
               "regenie_step1.covar" = get_file_id(args$covar, args$project),
               "regenie_step1.covarColList" = args$covarColList,
               "regenie_step1.catCovarList" = args$catCovarList,
               "regenie_step1.bt" = args$bt)

write_json(inputs, args$out, pretty=TRUE, auto_unbox=TRUE)
