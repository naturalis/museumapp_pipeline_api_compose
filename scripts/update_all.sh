#!/bin/bash

# file is assumed to be run from a subdir of the directory holding the docker-compose.yml file

DOCKER_COMPOSE=$(which docker-compose)
CRON_LOG=$(grep CRON_LOG ../.env | cut -d '=' -f2)
JOB_QUEUE_PATH_HOST=$(grep JOB_QUEUE_PATH_HOST ../.env | cut -d '=' -f2)

if [ -f "$LOCK_FILE" ]; then
    echo "update in progress (lock file exists); exiting"
    exit
else
    date > $LOCK_FILE

    echo "updating all sources"
    cd ..

    $DOCKER_COMPOSE run square_maker ./make_squares.sh >> $CRON_LOG
    $DOCKER_COMPOSE run reaper php ./public/run.php --source=natuurwijzer >> $CRON_LOG
    $DOCKER_COMPOSE run reaper php ./public/run.php --source=tentoonstelling >> $CRON_LOG
    $DOCKER_COMPOSE run reaper php ./public/run.php --source=topstukken >> $CRON_LOG
    $DOCKER_COMPOSE run nba_harvester php run.php --source=leenobjecten >> $CRON_LOG
    $DOCKER_COMPOSE run reaper php ./public/run.php --source=ttik >> $CRON_LOG
    $DOCKER_COMPOSE run nba_harvester php run.php --source=nba >> $CRON_LOG
    $DOCKER_COMPOSE run nba_harvester php run.php --source=favourites >> $CRON_LOG
    $DOCKER_COMPOSE run nba_harvester php run.php --source=taxa_no_objects >> $CRON_LOG
    $DOCKER_COMPOSE run pipeline php run.php --generate-files=0 >> $CRON_LOG
    $DOCKER_COMPOSE run crs_harvester php run.php >> $CRON_LOG
    $DOCKER_COMPOSE run nba_harvester php run.php --source=maps >> $CRON_LOG
    $DOCKER_COMPOSE run nba_harvester php run.php --source=iucn >> $CRON_LOG
    $DOCKER_COMPOSE run pipeline php run.php >> $CRON_LOG

    rm $LOCK_FILE
fi
