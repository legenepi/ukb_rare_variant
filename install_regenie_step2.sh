#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <projectid> <project directory>"
    exit 1
fi

PRED_LIST=fit_qt_out_pred.list
PROJECT_ID=$1
PROJECT_DIR=$2
OUTPUT_PREFIX=LF
COVARCOLLIST="PC{1:10}"
CATCOVARLIST=array
GENOS='/WGS/chr22/ukb24310_c22_b99*'
BASE=`dirname $0`
EXTRA_OPTIONS=extraOptions.json
INPUTS=inputs_regenie_step2.json
PHENO=LF_pheno.txt
COVAR=LF_covar.txt
DXCOMPILER=/tmp/dxCompiler.jar
WDL="regenie_step2.wdl"

./make_inputs_regenie_step2.R \
    --project $PROJECT_ID \
    --predList ${PROJECT_DIR}/${PRED_LIST} \
    --pheno ${PROJECT_DIR}/${PHENO} \
    --covar ${PROJECT_DIR}/${COVAR} \
    --covarColList $COVARCOLLIST \
    --catCovarList $CATCOVARLIST \
    --qt \
    --genos $GENOS \
    --outputPrefix $OUTPUT_PREFIX \
    --out $INPUTS &&

[ -x $DXCOMPILER ] || wget https://github.com/dnanexus/dxCompiler/releases/download/2.11.4/dxCompiler-2.11.4.jar -O $DXCOMPILER &&

cd ${BASE} &&

java -jar $DXCOMPILER compile $WDL -extras $EXTRA_OPTIONS -inputs $INPUTS -project $PROJECT_ID -folder $PROJECT_DIR -streamFiles perfile -f
