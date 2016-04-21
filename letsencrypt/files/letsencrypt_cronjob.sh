#!/bin/bash

{{ webserver_stop if webserver_stop is defined else '' }}

{% for setname, domainlist in domainsets.iteritems() %}
{{ check_letsencrypt_cert }} {{ domainlist|join(' ') }} > /dev/null || {{ obtain_letsencrypt_cert }} {{ domainlist|join(' ') }}
{% endfor %}

{{ webserver_start if webserver_start is defined else '' }}
