#!/bin/bash

# file is assumed to be run from a subdir of the directory holding the docker-compose.yml file

CUSTOM_LOAD_PATH=$1
JSON_LOAD_PATH_HOST=$(grep JSON_LOAD_PATH_HOST ../.env | cut -d '=' -f2,3)

if [ -z "$CUSTOM_LOAD_PATH" ]; then
  echo "no load path"
  exit
fi

CUSTOM_LOAD_PATH=$(echo "$CUSTOM_LOAD_PATH" | sed 's/\/$//')"/"


NUM_OF_FILES=$(ls -1 ${CUSTOM_LOAD_PATH}*.json 2> /dev/null | wc -l)

if [ "$NUM_OF_FILES" -eq 0 ]; then
  echo "no json files found in $LOAD_PATH"
  exit
fi

echo "about to load $NUM_OF_FILES files from $CUSTOM_LOAD_PATH [y/N]"
read KEY

if [ ! "$KEY" == "y" ]; then
    exit
fi

DOCKER_COMPOSE=$(which docker-compose)

echo "$(date +"%Y-%m-%d %H:%M:%S") - copying documents from $CUSTOM_LOAD_PATH"

rm ${JSON_LOAD_PATH_HOST}*.json
cp ${CUSTOM_LOAD_PATH}*.json $JSON_LOAD_PATH_HOST

cd ..

# $DOCKER_COMPOSE run -e ES_CONTROL_COMMAND=set_documents_status  -e ES_CONTROL_ARGUMENT=busy -e DEBUGGING=1 api_control

echo "$(date +"%Y-%m-%d %H:%M:%S") - deleting existing document versions"

for file in $CUSTOM_LOAD_PATH*.json
do
    ID=$(cat $file | jq -r '.id')
    $DOCKER_COMPOSE run -e ES_CONTROL_COMMAND=delete_document -e ES_CONTROL_ARGUMENT=$ID -e DEBUGGING=1 api_control
done

echo "$(date +"%Y-%m-%d %H:%M:%S") - loading documents"

$DOCKER_COMPOSE run -e ES_CONTROL_COMMAND=load_documents -e ES_CONTROL_ARGUMENT=/data/documents/load/ -e DEBUGGING=1 api_control
# $DOCKER_COMPOSE run -e ES_CONTROL_COMMAND=set_documents_status  -e ES_CONTROL_ARGUMENT=ready -e DEBUGGING=1 api_control

echo "$(date +"%Y-%m-%d %H:%M:%S") - done"
