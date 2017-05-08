#!/bin/bash

{% if webroot != '' -%}
PARAMETERS='-w /var/www/html/'
{% else -%}
PARAMETERS=''
{% endif -%}
LOG_FILE='/var/log/letsencrypt/letsencrypt.log'

[ ! -d '/var/log/letsencrypt/' ] && mkdir '/var/log/letsencrypt'

for DOMAIN in "$@"
do
    PARAMETERS="$PARAMETERS -d $DOMAIN"
done

{% if webroot != '' -%}
{{ letsencrypt_command }} certonly --quiet --webroot $PARAMETERS --non-interactive --expand >> "$LOG_FILE" 2>&1
{%- else -%}
{{ letsencrypt_command }} certonly --quiet $PARAMETERS --non-interactive --expand >> "$LOG_FILE" 2>&1
{%- endif %}

if [ $? != 0 ]; then
    echo Failed to obtain cert, see "$LOG_FILE"
    exit 1
fi
