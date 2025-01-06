#!/bin/bash

. RAP.config

if ! WORKFLOW=`dx ls --brief ${PROJECT_DIR}/regenie_step2_SV`; then
    echo "Workflow assocition_testing not found in ${PROJECT_DIR} on RAP, have you run install_workflows.sh?"
    exit 1
fi

if ! PRED_LIST="`dx ls --brief ${RESULTS}/fit_step1_pred.list`"; then
    echo "Step 1 predictions not found in ${RESULTS} on RAP, have you run step1?"
    exit 2
fi

dx mkdir -p $RESULTS

#{
#  "regenie_step2_SV.models": "Array[String] (optional, default = [\"additive\", \"dominant\", \"recessive\"])",
#  "regenie_step2_SV.covar": "File? (optional)",
#  "regenie_step2_SV.loco": "Array[File]",
#  "regenie_step2_SV.pheno": "File",
#  "regenie_step2_SV.catCovarList": "String? (optional)",
#  "regenie_step2_SV.covarColList": "String? (optional)",
#  "regenie_step2_SV.bt": "Boolean",
#  "regenie_step2_SV.genos": "Array[Array[File]]",
#  "regenie_step2_SV.pred_list": "File",
#  "regenie_step2_SV.exclude": "File? (optional)",
#  "regenie_step2_SV.output_prefix": "String"
#}

Rscript - <<-RSCRIPT
    suppressMessages(library(tidyverse))
    suppressMessages(library(jsonlite))
    source("R/make_inputs_functions.R")

    list(regenie_step2_SV.genos = get_genos("$EXOME_PATH", "$PROJECT_ID"),
         regenie_step2_SV.pheno = get_file_id("${PROJECT_DIR}/$pheno", "$PROJECT_ID"),
         regenie_step2_SV.covar = get_file_id("${PROJECT_DIR}/$covar", "$PROJECT_ID"),
         regenie_step2_SV.pred_list = get_file_id("${PRED_LIST}", "$PROJECT_ID"),
         regenie_step2_SV.loco = get_loco("${PRED_LIST}", "${RESULTS}"),
         regenie_step2_SV.covarColList = "$covarColList",
         regenie_step2_SV.catCovarList = "$catCovarList",
         regenie_step2_SV.bt = "$bt" == "bt",
         regenie_step2_SV.exclude = get_file_id("$EXCLUDE", "$PROJECT_ID"),
         regenie_step2_SV.output_prefix = "$ANALYSIS",
         regenie_step2_SV.models = str_split_1("$models", " ") %>% as.list) %>%
      write_json("${ANALYSIS}_step2_SV_inputs.json", pretty=TRUE, auto_unbox=TRUE)
RSCRIPT

[ -s $DXCOMPILER ] || wget $DXCOMPILER_URL -O $DXCOMPILER

java -jar $DXCOMPILER compile WDL/regenie_step2_SV.wdl -project $PROJECT_ID -compileMode IR -inputs ${ANALYSIS}_step2_SV_inputs.json &&
dx run --destination $RESULTS --brief -y -f ${ANALYSIS}_step2_SV_inputs.dx.json $WORKFLOW
