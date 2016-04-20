#!/bin/bash

PARAMETERS=''
LOG_FILE='/var/log/letsencrypt/letsencrypt.log'

for DOMAIN in "$@"
do
    PARAMETERS="$PARAMETERS -d $DOMAIN"
done

{{ stop_server if stop_server else '' }}
{{ letsencrypt_command }} certonly $PARAMETERS >> "$LOG_FILE" 2>&1
LE_STATUS=$?
{{ start_server if start_server else '' }}

if [ "$LE_STATUS" != 0 ]; then
    echo Failed to obtain cert, see "$LOG_FILE"
    exit 1
fi
