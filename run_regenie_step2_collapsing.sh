#!/bin/bash

. RAP.config

dx cd $PROJECT_DIR

if ! WORKFLOW=`dx ls --brief regenie_step2_collapsing`; then
    echo "Workflow regenie_step2_collapsing not found in ${PROJECT_DIR} on RAP, have you run install_workflows.sh?"
    exit 1
fi

if ! PRED_LIST="`dx ls --brief ${RESULTS}/${output_prefix}_step1_pred.list`"; then
    echo "Step 1 predictions not found in ${RESULTS} on RAP, have you run step1?"
    exit 2
fi

dx mkdir -p $RESULTS

Rscript - <<-RSCRIPT
    suppressMessages(library(tidyverse))
    suppressMessages(library(jsonlite))
    source("R/make_inputs_functions.R")

    params <- list(regenie_step2_collapsing.genos = get_genos("$EXOME_PATH", chroms=str_split_1("$chroms", " ")),
        regenie_step2_collapsing.pred_list = get_file_id("${PRED_LIST}"),
        regenie_step2_collapsing.loco = get_loco("${PRED_LIST}", "${RESULTS}"),
        regenie_step2_collapsing.bt = "$bt" == "true")
    file_opts <- get_config("$COLLAPSING_FILE_OPTIONS", "regenie_step2_collapsing") %>%
        map(get_file_id)
    upload_opts <- get_config("$COLLAPSING_UPLOAD_OPTIONS", "regenie_step2_collapsing") %>%
        map(~get_upload_id(., "${PROJECT_DIR}"))
    string_opts <- get_config("$COLLAPSING_STRING_OPTIONS", "regenie_step2_collapsing")
    c(params, file_opts, upload_opts, string_opts) %>%
        write_json("${output_prefix}_step2_collapsing_inputs.json", pretty=TRUE, auto_unbox=TRUE)
RSCRIPT

[ -s $DXCOMPILER ] || wget $DXCOMPILER_URL -O $DXCOMPILER

java -jar $DXCOMPILER compile WDL/regenie_step2_collapsing.wdl -project $PROJECT_ID -compileMode IR -inputs ${output_prefix}_step2_collapsing_inputs.json &&
dx run --destination $RESULTS --brief -y -f ${output_prefix}_step2_collapsing_inputs.dx.json $WORKFLOW
