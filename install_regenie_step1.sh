#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <projectid> <project directory>"
    exit 1
fi

PROJECT_ID=$1
PROJECT_DIR=$2
COVARCOLLIST="PC{1:10}"
CATCOVARLIST=array
BASE=`dirname $0`
EXTRA_OPTIONS=extraOptions.json
INPUTS=inputs_regenie_step1.json
PHENO=LF_pheno.txt
COVAR=LF_covar.txt
DXCOMPILER=/tmp/dxCompiler.jar
WDL="regenie_step1.wdl"

dx select $PROJECT_ID &&
dx mkdir -p $PROJECT_DIR &&
dx cd $PROJECT_DIR &&
dx ls | grep -w $PHENO && dx rm $PHENO
dx ls | grep -w $COVAR && dx rm $COVAR

dx upload ${BASE}/$PHENO &&
dx upload ${BASE}/$COVAR &&

./make_inputs_regenie_step1.R \
    --project $PROJECT_ID\
    --pheno ${PROJECT_DIR}/${PHENO} \
    --covar ${PROJECT_DIR}/${COVAR} \
    --covarColList $COVARCOLLIST \
    --catCovarList $CATCOVARLIST \
    --qt \
    --out $INPUTS &&

wget https://github.com/dnanexus/dxCompiler/releases/download/2.11.4/dxCompiler-2.11.4.jar -O $DXCOMPILER &&

cd ${BASE} &&

java -jar $DXCOMPILER compile $WDL -extras $EXTRA_OPTIONS -inputs $INPUTS -project $PROJECT_ID -folder $PROJECT_DIR -streamFiles perfile -f
