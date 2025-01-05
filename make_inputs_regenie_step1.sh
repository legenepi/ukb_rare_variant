#!/bin/bash

. RAP.config

Rscript - <<-RSCRIPT
    suppressMessages(library(tidyverse))
    suppressMessages(library(jsonlite))
    source("R/make_inputs_functions.R")

    list(regenie_step1.genos = get_genos("$GENO_BASE", "$PROJECT_ID"),
         regenie_step1.pheno = get_upload_id("$pheno", "$PROJECT_ID", "$PROJECT_DIR"),
         regenie_step1.covar = get_upload_id("$covar", "$PROJECT_ID", "$PROJECT_DIR"),
         regenie_step1.covarColList = "$covarColList",
         regenie_step1.catCovarList = "$catCovarList",
         regenie_step1.bt = "$bt" == "bt") %>%
      write_json("${ANALYSIS}_step1_inputs.json", pretty=TRUE, auto_unbox=TRUE)
RSCRIPT

[ -s $DXCOMPILER ] || wget $DXCOMPILER_URL -O $DXCOMPILER
java -jar $DXCOMPILER compile WDL/regenie_step1.wdl -project $PROJECT_ID -compileMode IR -inputs ${ANALYSIS}_step1_inputs.json