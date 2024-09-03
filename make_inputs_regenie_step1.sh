#!/bin/bash

. RAP.config

for i in ${ENTITIES// /.tsv }.tsv ${MINIMUM_DATA}.csv; do
    if ! dx ls ${INPUTS}/$i > /dev/null; then
        echo "Required input $i missing from ${INPUTS}, have you run extract_fields.sh?"
        exit 1
    fi
done

export $KEYS $OPTIONS

Rscript - <<-RSCRIPT
    suppressMessages(library(tidyverse))
    suppressMessages(library(jsonlite))
    source("R/make_inputs_functions.R")

    minimum_data <- list(phenotype_generation.tab_data=map("$tab_data", get_file_id))
    required_files <- get_config("$KEYS", "phenotype_generation") %>%
        map(get_file_id)
    options <- get_config("$OPTIONS", "phenotype_generation") %>%
        map(~get_upload_id(., "$PROJECT_ID", "$PROJECT_DIR"))
    c(minimum_data, required_files, options) %>%
        write_json("${PHENOTYPES_GENERATED}.json", pretty=TRUE, auto_unbox=TRUE)
RSCRIPT

[ -s $DXCOMPILER ] || wget $DXCOMPILER_URL -O $DXCOMPILER
java -jar $DXCOMPILER compile WDL/phenotype_generation.wdl -project $PROJECT_ID -compileMode IR -inputs ${PHENOTYPES_GENERATED}.json
