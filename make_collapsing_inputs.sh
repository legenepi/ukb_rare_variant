#!/bin/bash

#{
#  "collapsing.covarColList": "String? (optional)",
#  "collapsing.pred_list": "File",
#  "collapsing.output_prefix": "String",
#  "collapsing.aaf_bins": "String (optional, default = \"0.01,0.001,0.0001,0.00001\")",
#  "collapsing.mask": "File",
#  "collapsing.setlist": "File",
#  "collapsing.loco": "Array[File]",
#  "collapsing.annot": "File",
#  "collapsing.pheno": "File",
#  "collapsing.catCovarList": "String? (optional)",
#  "collapsing.exclude": "File? (optional)",
#  "collapsing.genos": "Array[Array[File]]",
#  "collapsing.covar": "File? (optional)",
#  "collapsing.tests": "String (optional, default = \"acato,skato\")",
#  "collapsing.maxaaf": "Float (optional, default = 0.01)",
#  "collapsing.joint_tests": "String (optional, default = \"acat,sbat\")"
#}

if [ $# -lt 4 ]; then
    echo "Usage: $0 <OUTPUT_PREFIX> <PRED_LIST> <PHENOPATH> <MASK> [ COVARPATH COVARCOLLIST CATCOVARLIST ]"
    exit 1
fi

OUTPUT_PREFIX=$1
PRED_LIST=$2
PHENOPATH=$3
MASK=$4
COVARPATH=$5
COVARCOLLIST=$6
CATCOVARLIST=$7
ANNOT='/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.annotations.txt.gz'
SETLIST='/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.sets.txt.gz'
EXCLUDE='/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.90pct10dp_qc_variants.txt'
CHROMS=23

PRED_LIST_FILE=dx://`dx ls --brief $PRED_LIST`
PHENOFILE=dx://`dx ls --brief $PHENOPATH`
COVARFILE=dx://`dx ls --brief $COVARPATH`

dx ls -l '/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/ukb23158_c*_b0_v1.*' | awk '
BEGIN {
    OFS=","
    print "{"
    print "\t\"collapsing.genos\": ["
}

{
    gsub("[()]", "", $7)
    file[$6]=$7
}

END {
    chroms = '$CHROMS'
    for (i=1; i<=chroms; i++) {
        chr=(i < 23 ? i : "X")
        base="ukb23158_c"chr"_b0_v1"
        print "\t\t[\"dx://"file[base".bed"]"\"", "\"dx://"file[base".bim"]"\"", "\"dx://"file[base".fam"]"\""(i<chroms ? "]," : "]")
    }
    print "\t],"
    if ("'$COVARFILE'")
        print "\t\"collapsing.covar\": \"'$COVARFILE'\","
    if ("'$COVARCOLLIST'")
        print "\t\"collapsing.covarColList\": \"'$COVARCOLLIST'\","
    if ("'$CATCOVARLIST'")
        print "\t\"collapsing.catCovarList\": \"'$CATCOVARLIST'\","
    print "\t\"collapsing.pheno\": \"'$PHENOFILE'\","
}'

echo -e "\t\"collapsing.pred_list\": \"dx://`dx ls --brief $PRED_LIST`\","

echo -e "\t\"collapsing.loco\": ["
DIRNAME=`dirname $PRED_LIST`
dx cat $PRED_LIST | while read p l; do
    echo -e "\t\t\"dx://`dx ls --brief ${DIRNAME}/$l`\""
done | sed '$ ! s/$/,/'
echo -e "\t],"

ANNOT_FILE=`dx ls --brief "$ANNOT"`
SETLIST_FILE=`dx ls --brief "$SETLIST"`
EXCLUDE_FILE=`dx ls --brief "$EXCLUDE"`
echo -e "\t\"collapsing.annot\": \"dx://${ANNOT_FILE}\","
echo -e "\t\"collapsing.setlist\": \"dx://${SETLIST_FILE}\","
echo -e "\t\"collapsing.exclude\": \"dx://${EXCLUDE_FILE}\","
echo -e "\t\"collapsing.mask\": \"dx://`dx ls --brief $MASK`\","
echo -e "\t\"collapsing.output_prefix\": \"$OUTPUT_PREFIX\""
echo "}"
