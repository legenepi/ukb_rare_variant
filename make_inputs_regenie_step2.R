#!/usr/bin/env Rscript

GENO_BASE <- "/Bulk/Genotype Results/Genotype calls/ukb22418_c*"

'Usage:
  make_inputs_regenie_step2.R [--project STRING] --predList FILE --pheno FILE --covar FILE --covarColList STRING --catCovarList STRING (--bt | --qt) --genos STRING --outputPrefix STRING --out FILE

Options:
  --predList FILE       Predictions file from regenie step 1
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
  --genos STRING        Genotype files glob
  --outputPrefix STRING Output prefix for association results
  --out FILE            output JSON file
' -> doc

suppressMessages(library(docopt))
suppressMessages(library(tidyverse))
suppressMessages(library(jsonlite))
source("make_inputs_functions.R")

args <- docopt(doc)

inputs <- list("regenie_step2.genos" = get_genos(GENO_BASE, args$project),
               "regenie_step2.pheno" = get_file_id(args$pheno, args$project),
               "regenie_step2.covar" = get_file_id(args$covar, args$project),
               "regenie_step2.covarColList" = args$covarColList,
               "regenie_step2.catCovarList" = args$catCovarList,
               "regenie_step2.pred_list" = get_file_id(args$predList, args$project),
               "regenie_step2.loco" = get_loco(args$predList, args$project),
               "regenie_step2.output_prefix" = args$outputPrefix,
               "regenie_step2.bt" = args$bt)

write_json(inputs, args$out, pretty=TRUE, auto_unbox=TRUE)
