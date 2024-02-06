#!/bin/bash

#{
#  "ExWAS.output_prefix": "LF",
#  "ExWAS.covar": "dx://file-Gfgxpk8JZbzy8bpP263KK057",
#  "ExWAS.genos": [
#      ["dx://file-G986xz8JykJj785jPzzq4YFY","dx://file-G986vJjJykJXQ0fq3yB37Fy6","dx://file-GGX5qKjJPbgyVx1G3V68xGJb"],	
#	  ["dx://file-G97gbg0JykJVV3jf4gy53JX5","dx://file-G97gPz8JykJb4Yvy7k8JjV0x","dx://file-GGX5qj0JPbgzFj9KKkjpgbvG"]
#  ],
#  "ExWAS.loco": ["dx://file-Gfj1B28JQfVJv3Yq9b9K47Zk","dx://file-Gfj1B28JQfVJ6y8zJ0kgZ1kz","dx://file-Gfj1B28JQfV5KvyVB196vXp6"],
#  "ExWAS.pheno": "dx://file-Gfgxpj8JZbzVZ4q3b22J3642",
#  "ExWAS.pred_list": "dx://file-Gfj1B28JQfV640JZxjgkg8Gk",
#  "ExWAS.models": ["additive", "dominant", "recessive"]
#}

PRED_LIST=$1
PHENOPATH=$2
COVARPATH=$3
COVARCOLLIST=$4
CATCOVARLIST=$5
OUTPUT_PREFIX=$6

PRED_LIST_FILE=dx://`dx ls --brief $PRED_LIST`
PHENOFILE=dx://`dx ls --brief $PHENOPATH`
COVARFILE=dx://`dx ls --brief $COVARPATH`

dx ls -l '/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/ukb23158_c*_b0_v1.*' | awk '
BEGIN {
    OFS=","
    print "{"
    print "\t\"ExWAS.genos\": ["
}

{
    gsub("[()]", "", $7)
    file[$6]=$7
}

END {
    chroms = 23
    for (i=1; i<=chroms; i++) {
        chr=(i < 23 ? i : "X")
        base="ukb23158_c"chr"_b0_v1"
        print "\t\t[\"dx://"file[base".bed"]"\"", "\"dx://"file[base".bim"]"\"", "\"dx://"file[base".fam"]"\""(i<chroms ? "]," : "]")
    }
    print "\t],"
    if ("'$COVARFILE'")
        print "\t\"ExWAS.covar\": \"'$COVARFILE'\","
    if ("'$COVARCOLLIST'")
        print "\t\"ExWAS.covarColList\": \"'$COVARCOLLIST'\","
    if ("'$CATCOVARLIST'")
        print "\t\"ExWAS.catCovarList\": \"'$CATCOVARLIST'\","
    print "\t\"ExWAS.pheno\": \"'$PHENOFILE'\","
}'

echo -e "\t\"ExWAS.pred_list\": \"dx://`dx ls --brief $PRED_LIST`\","

echo -e "\t\"ExWAS.loco\": ["
DIRNAME=`dirname $PRED_LIST`
dx cat $PRED_LIST | while read p l; do
    echo -e "\t\t\"dx://`dx ls --brief ${DIRNAME}/$l`\""
done | sed '$ ! s/$/,/'
echo -e "\t],"

echo -e "\t\"ExWAS.models\": [\"additive\", \"dominant\", \"recessive\"],"
echo -e "\t\"ExWAS.output_prefix\": \"$OUTPUT_PREFIX\""
echo "}"
