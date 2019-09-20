#!/bin/bash

DOCKER_COMPOSE=$(which docker-compose)
CRON_LOG=/data/pipeline/log/cron.log

echo "updating all sources"

cd /home/maarten/Documents/museumapp/museumapp_pipeline_api_compose/
$DOCKER_COMPOSE run square_maker ./make_squares.sh >> $CRON_LOG
$DOCKER_COMPOSE run reaper php ./public/run.php --source=natuurwijzer >> $CRON_LOG
$DOCKER_COMPOSE run reaper php ./public/run.php --source=tentoonstelling >> $CRON_LOG
$DOCKER_COMPOSE run reaper php ./public/run.php --source=topstukken >> $CRON_LOG
$DOCKER_COMPOSE run nba_harvester php run.php --source=brahms >> $CRON_LOG
$DOCKER_COMPOSE run nba_harvester php run.php --source=leenobjecten >> $CRON_LOG
$DOCKER_COMPOSE run reaper php ./public/run.php --source=ttik >> $CRON_LOG
$DOCKER_COMPOSE run nba_harvester php run.php --source=nba >> $CRON_LOG
$DOCKER_COMPOSE run nba_harvester php run.php --source=favourites >> $CRON_LOG
$DOCKER_COMPOSE run nba_harvester php run.php --source=taxa_no_objects >> $CRON_LOG

# $DOCKER_COMPOSE run crs_harvester php run.php >> $CRON_LOG

$DOCKER_COMPOSE run pipeline php run.php --generate-files=0 >> $CRON_LOG
$DOCKER_COMPOSE run nba_harvester php run.php --source=maps >> $CRON_LOG
$DOCKER_COMPOSE run nba_harvester php run.php --source=iucn >> $CRON_LOG
$DOCKER_COMPOSE run pipeline php run.php >> $CRON_LOG
