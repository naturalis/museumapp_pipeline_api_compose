#!/bin/bash

# file is assumed to be run from a subdir of the directory holding the docker-compose.yml file

JOB_QUEUE_PATH_HOST=$(grep JOB_QUEUE_PATH_HOST ../.env | cut -d '=' -f2,3)
DOCKER_COMPOSE=$(which docker-compose)

HAVE_JOB=false
    
for file in $JOB_QUEUE_PATH_HOST*
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

SOURCES_GROUP_1=('natuurwijzer' 'tentoonstelling' 'topstukken' 'ttik')
SOURCES_GROUP_2=('leenobjecten' 'favourites' 'taxa_no_objects' 'maps' 'brahms' 'nba' 'iucn' 'ttik_photo_species')
SOURCES_GROUP_3=('crs')
SOURCES_GROUP_4=('image_squares')

COMMAND_GROUP_1="reaper php ./public/run.php --source="
COMMAND_GROUP_2="nba_harvester php run.php --source="
COMMAND_GROUP_3="crs_harvester php run.php"
COMMAND_GROUP_4="square_maker ./make_squares.sh"

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

for t in ${SOURCES_GROUP_4[@]}; do
    if [ "$SOURCE" == "$t" ]; then
        COMMAND=$COMMAND_GROUP_4
    fi
done

if [ "$COMMAND" = "" ]; then
    echo "no matching command for $SOURCE"
    exit
fi


if [ "$HAVE_JOB" = true ] && [ "$ACTION" == "refresh" ] ; then
    echo "running $SOURCE $ACTION"
    echo "{\"action\":\"refreshing\",\"source\":\"$SOURCE\"}" > $JOB

    cd ..
    $DOCKER_COMPOSE run $COMMAND
    rm $JOB
    echo "done"
fi


