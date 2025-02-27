#!/bin/bash

. RAP.config

dx cd ${PROJECT_DIR}

if ! WORKFLOW=`dx ls --brief regenie_step1`; then
    echo "Workflow regenie_step1 not found in ${PROJECT_DIR} on RAP, have you run install_workflows.sh?"
    exit 1
fi

dx mkdir -p $RESULTS

Rscript - <<-RSCRIPT
    suppressMessages(library(tidyverse))
    suppressMessages(library(jsonlite))
    source("R/make_inputs_functions.R")

    list(regenie_step1.genos = get_genos("$GENO_BASE", chroms=as.character(1:22)),
         regenie_step1.pheno = get_upload_id("$pheno", "$PROJECT_DIR"),
         regenie_step1.covar = get_upload_id("$covar", "$PROJECT_DIR"),
         regenie_step1.covarColList = "$covarColList",
         regenie_step1.catCovarList = "$catCovarList",
         regenie_step1.bt = "$bt" == "true",
         regenie_step1.output_prefix = "$output_prefix") %>%
      write_json("${output_prefix}_step1_inputs.json", pretty=TRUE, auto_unbox=TRUE)
RSCRIPT

[ -s $DXCOMPILER ] || wget $DXCOMPILER_URL -O $DXCOMPILER

java -jar $DXCOMPILER compile WDL/regenie_step1.wdl -project $PROJECT_ID -compileMode IR -inputs ${output_prefix}_step1_inputs.json &&
dx run --destination $RESULTS --brief -y -f ${output_prefix}_step1_inputs.dx.json $WORKFLOW
