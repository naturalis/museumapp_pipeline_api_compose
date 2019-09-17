#!/bin/bash

PUBLISH_DIR=/data/pipeline/documents/publish/
LOAD_DIR=/data/pipeline/documents/load/

SIGNAL_FILE_READY=${PUBLISH_DIR}.ready
SIGNAL_FILE_WORKING=${PUBLISH_DIR}.busy

DOCKER_DIR=/opt/museumapp_pipeline_api_compose

MINIMUM_NUM_OF_FILES=1000
NUM_OF_FILES=$(ls -1 ${PUBLISH_DIR}*.json 2> /dev/null | wc -l)

echo "$(date +"%Y-%m-%d %H:%M:%S") - loading documents from $PUBLISH_DIR"

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
  echo "found only $NUM_OF_FILES documents in $PUBLISH_DIR (threshold: $MINIMUM_NUM_OF_FILES)"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - done"
  exit
fi

echo "loading $NUM_OF_FILES documents"

rm $SIGNAL_FILE_READY
touch $SIGNAL_FILE_WORKING 
rm ${LOAD_DIR}*.json
mv ${PUBLISH_DIR}*.json $LOAD_DIR
cd $DOCKER_DIR

/usr/local/bin/docker-compose run -e ES_CONTROL_COMMAND=set_documents_status  -e ES_CONTROL_ARGUMENT=busy -e DEBUGGING=1 api_control
/usr/local/bin/docker-compose run -e ES_CONTROL_COMMAND=delete_documents -e DEBUGGING=1 api_control
/usr/local/bin/docker-compose run -e ES_CONTROL_COMMAND=load_documents -e ES_CONTROL_ARGUMENT=/data/documents/load/ -e DEBUGGING=1 api_control
#/usr/local/bin/docker-compose run -e ES_CONTROL_COMMAND=load_documents -e ES_CONTROL_ARGUMENT=/data/documents/load/en/ -e DEBUGGING=1 api_control
/usr/local/bin/docker-compose run -e ES_CONTROL_COMMAND=set_documents_status  -e ES_CONTROL_ARGUMENT=ready -e DEBUGGING=1 api_control

rm $SIGNAL_FILE_WORKING

echo "$(date +"%Y-%m-%d %H:%M:%S") - done"
