#!/bin/bash

PARAMETERS=''
LOG_FILE='/var/log/letsencrypt/letsencrypt.log'

for DOMAIN in "$@"
do
    PARAMETERS="$PARAMETERS -d $DOMAIN"
done

{{ letsencrypt_command }} certonly $PARAMETERS >> "$LOG_FILE" 2>&1

if [ $? != 0 ]; then
    echo Failed to obtain cert, see "$LOG_FILE"
    exit 1
fi
