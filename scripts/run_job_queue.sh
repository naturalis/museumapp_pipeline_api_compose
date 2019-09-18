#!/bin/bash

QUEUE_PATH=/data/pipeline/queue/
DOCKER_COMPOSE_PATH=/opt/composeproject/

HAVE_JOB=false
    
for file in $QUEUE_PATH*
do
    if [[ -f $file ]]; then
        SOURCE=$(cat $file | jq -r '.source')
        ACTION=$(cat $file | jq -r '.action')
        JOB=$file
        if [[ "$ACTION" == "refresh" ]]; then
            HAVE_JOB=true
            break
        fi
        if [[ "$ACTION" == "publish" ]]; then
            HAVE_JOB=true
            break
        fi
    fi
done

if [ ! "$HAVE_JOB" = true ]; then
    exit
fi


if [ "$SOURCE" = "image_squares" ] && [ "$ACTION" == "refresh" ]; then
    echo "running $SOURCE $ACTION"
    echo "{\"action\":\"refreshing\",\"source\":\"$SOURCE\"}" > $JOB

    cd /data/pipeline/image_squares
    /data/pipeline/image_squares/make_squares.sh

    rm $JOB
    echo "done"
    exit
fi


SOURCES_GROUP_1=('natuurwijzer' 'tentoonstelling' 'topstukken' 'ttik')
SOURCES_GROUP_2=('leenobjecten' 'favourites' 'taxa_no_objects' 'maps' 'brahms' 'nba' 'iucn')
SOURCES_GROUP_3=('crs')


COMMAND_GROUP_1="reaper php ./public/run.php --source="
COMMAND_GROUP_2="nba_harvester php run.php --source="
COMMAND_GROUP_3="crs_harvester php run.php"

COMMAND=""

for t in ${SOURCES_GROUP_1[@]}; do
    if [ "$SOURCE" == "$t" ]; then
        COMMAND=$COMMAND_GROUP_1$SOURCE
    fi
done

for t in ${SOURCES_GROUP_2[@]}; do
    if [ "$SOURCE" == "$t" ]; then
        COMMAND=$COMMAND_GROUP_2$SOURCE
    fi
done

for t in ${SOURCES_GROUP_3[@]}; do
    if [ "$SOURCE" == "$t" ]; then
        COMMAND=$COMMAND_GROUP_3
    fi
done

if [ "$COMMAND" = "" ]; then
    echo "no matching command for $SOURCE"
    exit
fi

if [ "$HAVE_JOB" = true ] && [ "$ACTION" == "refresh" ] ; then
    echo "running $SOURCE $ACTION"
    echo "{\"action\":\"refreshing\",\"source\":\"$SOURCE\"}" > $JOB

    cd $DOCKER_COMPOSE_PATH
    /usr/local/bin/docker-compose run $COMMAND
    rm $JOB
    echo "done"
fi


