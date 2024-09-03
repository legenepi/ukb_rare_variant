#!/bin/bash

. RAP.config

dx select $PROJECT_ID &&
dx mkdir -p $PROJECT_DIR &&
dx cd $PROJECT_DIR &&
dx ls | grep -w Dockerfile && dx rm Dockerfile
dx ls | grep -w $DOCKER_SAVE && dx rm $DOCKER_SAVE

dx upload Dockerfile 

dx run --brief -y --wait --watch --name update_docker swiss-army-knife \
	-iin=Dockerfile \
    -icmd="docker build -t $DOCKER_TAG --build-arg PLINK2_VERSION=$PLINK2_VERSION . && docker save $DOCKER_TAG | gzip > $DOCKER_SAVE" &&
#    -icmd="docker build -t $DOCKER_TAG --build-arg PLINK2_VERSION=$PLINK2_VERSION --build-arg REGENIE_VERSION=$REGENIE_VERSION . && docker save $DOCKER_TAG | gzip > $DOCKER_SAVE" &&

DOCKER_FILE_ID=`dx ls --brief $DOCKER_SAVE` &&

cat <<-JSON > $EXTRA_OPTIONS
	{
	    "defaultRuntimeAttributes" : {
	        "docker" : "dx://${DOCKER_FILE_ID}"
	    }
	}	
JSON
