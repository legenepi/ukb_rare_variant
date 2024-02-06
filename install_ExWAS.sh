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
BASE=`dirname $0`
EXTRA_OPTIONS=extraOptions.json
INPUTS=inputs_ExWAS.json
PHENO=pheno.txt
COVAR=covar.txt
DXCOMPILER=/tmp/dxCompiler.jar
WDL="ExWAS.wdl"

./make_ExWAS_inputs.sh ${PROJECT_DIR}/${PRED_LIST} ${PROJECT_DIR}/${PHENO} ${PROJECT_DIR}/${COVAR} "$COVARCOLLIST" "$CATCOVARLIST" $OUTPUT_PREFIX > $INPUTS &&

[ -x $DXCOMPILER ] || wget https://github.com/dnanexus/dxCompiler/releases/download/2.11.4/dxCompiler-2.11.4.jar -O $DXCOMPILER &&

cd ${BASE} &&

java -jar $DXCOMPILER compile $WDL -extras $EXTRA_OPTIONS -inputs $INPUTS -project $PROJECT_ID -folder $PROJECT_DIR -streamFiles perfile -f
