#!/bin/bash

# cron this file every minute!
CRON_LOG=$(grep CRON_LOG ../.env | cut -d '=' -f2)

MINUTES=$(date "+%M")
MINUTES=$(echo $MINUTES | sed 's/^0*//')

MINUTES_MOD_TEN=$(($MINUTES % 10))
MINUTES_MOD_ONE=$(($MINUTES % 1)) # yes i know

if [ "$MINUTES_MOD_ONE" -eq  0 ]; then
    # */1 * * * * /opt/scripts/run_job_queue.sh
    ./run_job_queue.sh >> $CRON_LOG
fi

if [ "$MINUTES_MOD_TEN" -eq  0 ]; then
    # 0,10,20,30,40,50 * * * * /opt/scripts/load_documents.sh
    ./load_documents.sh >> $CRON_LOG
    ./leenobjectmedia.sh >> $CRON_LOG
fi

TIME_OF_DAY=$(date "+%H:%M")
UPDATE_ALL="03:00"

if [ "$TIME_OF_DAY" == "$UPDATE_ALL" ]; then
    ./update_all.sh
fi
