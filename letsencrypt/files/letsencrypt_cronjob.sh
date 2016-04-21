#!/bin/bash

{{ webserver_stop if webserver_stop is defined else '' }}

{% for setname, domainlist in domainsets.iteritems() %}
{{ renew_letsencrypt_cert }} {{ domainlist|join(' ') }}
{% endfor %}

{{ webserver_start if webserver_start is defined else '' }}
