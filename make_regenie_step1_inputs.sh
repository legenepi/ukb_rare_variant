#!/bin/bash

PHENOPATH=$1
COVARPATH=$2
COVARCOLLIST=$3
CATCOVARLIST=$4
PHENOFILE=dx://`dx ls --brief $PHENOPATH`
COVARFILE=dx://`dx ls --brief $COVARPATH`

dx ls -l '/Bulk/Genotype Results/Genotype calls/ukb22418_c*_b0_v2.*' | awk '
BEGIN {
    OFS=","
    print "{"
    print "\t\"regenie_step1.genos\": ["
}

{
    gsub("[()]", "", $7)
    file[$6]=$7
}

END {
    chroms = 22
    for (i=1; i<=chroms; i++) {
        base="ukb22418_c"i"_b0_v2"
        print "\t\t[\"dx://"file[base".bed"]"\"", "\"dx://"file[base".bim"]"\"", "\"dx://"file[base".fam"]"\""(i<chroms ? "]," : "]")
    }
    print "\t],"
    if ("'$COVARFILE'")
        print "\t\"regenie_step1.covar\": \"'$COVARFILE'\","
    if ("'$COVARCOLLIST'")
        print "\t\"regenie_step1.covarColList\": \"'$COVARCOLLIST'\","
    if ("'$CATCOVARLIST'")
        print "\t\"regenie_step1.catCovarList\": \"'$CATCOVARLIST'\","
    print "\t\"regenie_step1.pheno\": \"'$PHENOFILE'\""
    print "}"
}'
