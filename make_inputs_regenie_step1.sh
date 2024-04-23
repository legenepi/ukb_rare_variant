#!/bin/bash

. workflow_functions.sh

while getopts "i:p:c:l:v:g:hb:" opt; do
    case "${opt}" in
        h)
            usage
            exit 0
            ;;
        g)
            GENO_PATH=$OPTARG
            ;;
        i)
            IFS=,
            CHROMS=($OPTARG)
            unset IFS
            ;;
        p)
            PHENO=$OPTARG
            ;;
        c)
            COVAR=$OPTARG
            ;;
        l)
            COVARCOLLIST=$OPTARG
            ;;
        b)
            CATCOVARLIST=$OPTARG
            ;;
    esac
done

[ ${#CHROMS[@]} -gt 0 ] || CHROMS=({1..23})

cat <<EOT
{
    `get_genos regenie_step1.genos "/Bulk/Genotype Results/Genotype calls" ${CHROMS[@]}`,
    `get_file regenie_step1.pheno "${PHENO}"`,
EOT
if [ -n "$COVARCOLLIST" ]; then
    cat <<EOT
    "regenie_step1.covarColList": "$COVARCOLLIST",
EOT
fi
if [ -n "$CATCOVARLIST" ]; then
    cat <<EOT
    "regenie_step1.catCovarList": "$CATCOVARLIST",
EOT
fi
cat <<EOT
    `get_file regenie_step1.covar "${COVAR}"`
}
EOT
