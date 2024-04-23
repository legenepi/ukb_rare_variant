#!/bin/bash

get_file() {
    KEY=$1
    RAP_PATH=$2
    FILE=`dx ls --brief $RAP_PATH`
    cat <<EOT
"${KEY}": "dx://${FILE}"
EOT
}

get_geno_file() {
    CHR=$1
    EXT=$2
    key=`echo ${!files[@]} | tr ' ' '\n' | grep ".*_c${CHR}_.*${EXT}"`
    echo -n ${files[$key]}
}

get_genos() {
    KEY=$1
    PREFIX=$2
    shift 2
    [ $# -gt 0 ] && CHROMS=($@) || CHROMS=({1..23})

    declare -A files

    while read k v; do
        files[$k]=${v//[()]}
    done < <(dx ls -l "${PREFIX}/ukb\*_c\*" | awk '{ print $6, $7 }')

    cat <<EOT
"${KEY}": [
EOT

    for i in ${CHROMS[@]}; do
        [ $i -lt 23 ] && c=$i || c=X
        BED=`get_geno_file $files $c .bed`
        BIM=`get_geno_file $files $c .bim`
        FAM=`get_geno_file $files $c .fam`
        [ $i -lt ${CHROMS[-1]} ] && ORS="," || ORS=""
        cat <<EOT
        ["dx://${BED}","dx://${BIM}","dx://${FAM}"]$ORS
EOT
    done

    cat <<EOT
    ]
EOT
}
