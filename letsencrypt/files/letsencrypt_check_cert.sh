#!/bin/bash

FIRST_CERT=$1

for DOMAIN in "$@"
do
    openssl x509 -in /etc/letsencrypt/live/$FIRST_CERT/cert.pem -noout -text | grep DNS:${DOMAIN} > /dev/null || exit 1
done
CERT=$(date -d "$(openssl x509 -in /etc/letsencrypt/live/$FIRST_CERT/cert.pem -enddate -noout | cut -d'=' -f2)" "+%s")
CURRENT=$(date "+%s")
REMAINING=$((($CERT - $CURRENT) / 60 / 60 / 24))
[ "$REMAINING" -gt "30" ] || exit 1
echo Domains $@ are in cert and cert is valid for $REMAINING days
