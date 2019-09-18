#!/bin/bash

INCOMING_PATH=/data/pipeline/minio/leenobjectimages
MEDIA_PATH=/data/pipeline/leenobject_images

if [ ! -d "$MEDIA_PATH" ]; then
    mkdir $MEDIA_PATH
fi

mv $INCOMING_PATH/* $MEDIA_PATH
