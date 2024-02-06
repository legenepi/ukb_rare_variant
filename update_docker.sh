#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 <projectid> <project directory>"
	exit 1
fi

PROJECT_ID=$1
PROJECT_DIR=$2
BASE=`dirname $0`
DOCKER_TAG=nshrine/rare_variant_analysis
DOCKER_SAVE=rare_variant_analysis.docker.tar.gz
EXTRA_OPTIONS=extraOptions.json

dx select $PROJECT_ID &&
dx mkdir -p $PROJECT_DIR &&
dx cd $PROJECT_DIR &&
dx ls | grep -w Dockerfile && dx rm Dockerfile
dx ls | grep -w $DOCKER_SAVE && dx rm $DOCKER_SAVE

dx upload ${BASE}/Dockerfile &&

dx run --brief -y --wait --watch swiss-army-knife \
	-iin=Dockerfile \
	-icmd="docker build -t $DOCKER_TAG . && docker save $DOCKER_TAG | gzip > $DOCKER_SAVE" &&

DOCKER_FILE_ID=`dx ls --brief $DOCKER_SAVE` &&

cat <<-JSON > $EXTRA_OPTIONS
	{
	    "defaultRuntimeAttributes" : {
	        "docker" : "dx://${DOCKER_FILE_ID}"
	    }
	}	
JSON
