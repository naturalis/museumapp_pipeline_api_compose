#!/bin/bash

# file is assumed to be run from a subdir of the directory holding the docker-compose.yml file

JSON_PUBLISH_PATH_HOST=$(grep JSON_PUBLISH_PATH_HOST ../.env | cut -d '=' -f2,3)
JSON_LOAD_PATH_HOST=$(grep JSON_LOAD_PATH_HOST ../.env | cut -d '=' -f2,3)
JSON_CUSTOM_PATH_HOST=$(grep JSON_CUSTOM_PATH_HOST ../.env | cut -d '=' -f2,3)

SIGNAL_FILE_READY=${JSON_PUBLISH_PATH_HOST}.ready
SIGNAL_FILE_WORKING=${JSON_PUBLISH_PATH_HOST}.busy

DOCKER_COMPOSE=$(which docker-compose)

MINIMUM_NUM_OF_FILES=1000
NUM_OF_FILES=$(ls -1 ${JSON_PUBLISH_PATH_HOST}*.json 2> /dev/null | wc -l)

echo "$(date +"%Y-%m-%d %H:%M:%S") - loading documents from $JSON_PUBLISH_PATH_HOST"

if [ "$NUM_OF_FILES" -eq 0 ]; then
  echo "$(date +"%Y-%m-%d %H:%M:%S") - nothing to load"
  exit
fi

if [ ! -f "$SIGNAL_FILE_READY" ]; then
  echo "signal file $SIGNAL_FILE_READY missing"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - done"
  exit
fi

if [ "$NUM_OF_FILES" -lt "$MINIMUM_NUM_OF_FILES" ]; then
  echo "found only $NUM_OF_FILES documents in $JSON_PUBLISH_PATH_HOST (threshold: $MINIMUM_NUM_OF_FILES)"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - done"
  exit
fi

echo "loading $NUM_OF_FILES documents"

rm $SIGNAL_FILE_READY
touch $SIGNAL_FILE_WORKING 
rm ${JSON_LOAD_PATH_HOST}*.json
mv ${JSON_PUBLISH_PATH_HOST}*.json $JSON_LOAD_PATH_HOST

NUM_OF_CUSTOM_FILES=$(ls -1 ${JSON_CUSTOM_PATH_HOST}*.json 2> /dev/null | wc -l)
if [ "$NUM_OF_CUSTOM_FILES" -gt 0 ]; then
  echo "copying & loading $NUM_OF_CUSTOM_FILES custom documents"
  cp ${JSON_CUSTOM_PATH_HOST}*.json $JSON_LOAD_PATH_HOST
fi

cd ..

$DOCKER_COMPOSE run -e ES_CONTROL_COMMAND=set_documents_status  -e ES_CONTROL_ARGUMENT=busy -e DEBUGGING=1 api_control
$DOCKER_COMPOSE run -e ES_CONTROL_COMMAND=delete_documents -e DEBUGGING=1 api_control
$DOCKER_COMPOSE run -e ES_CONTROL_COMMAND=load_documents -e ES_CONTROL_ARGUMENT=/data/documents/load/ -e DEBUGGING=1 api_control
$DOCKER_COMPOSE run -e ES_CONTROL_COMMAND=set_documents_status  -e ES_CONTROL_ARGUMENT=ready -e DEBUGGING=1 api_control

rm $SIGNAL_FILE_WORKING

echo "$(date +"%Y-%m-%d %H:%M:%S") - done"
