#!/bin/bash

{{ webserver_stop if webserver_stop is defined else '' }}

{% for setname, domainlist in domainsets.iteritems() %}
{{ letsencrypt_check_cert }} {{ domainlist|join(' ') }} > /dev/null || {{ letsencrypt_obtain_cert }} {{ domainlist|join(' ') }}
{% endfor %}

{{ webserver_start if webserver_start is defined else '' }}
