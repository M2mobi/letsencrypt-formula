{%- set account = salt['grains.get']('ec2_tags:account', '') -%}
{%- set environment = salt['grains.get']('ec2_tags:environment', '') -%}
#!/bin/bash

{{ webserver_stop if webserver_stop is defined else '' -}}

{%- for setname, domainlist in domainsets.iteritems() %}
{{ renew_letsencrypt_cert }} {{ domainlist|join(' ') }}
{%- endfor %}

{%- set mine_query = "G@ec2_tags:account:" + account + " and G@ec2_tags:environment:" + environment + " and G@ec2_tags:role:webserver and G@ec2_tags:purpose:frontend and G@ec2_tags:hierarchy:secondary" %}
{%- for minion, hostname in salt['mine.get'](mine_query, 'name', 'compound').items() %}
rsync -lr -e 'ssh -i /home/letsencrypt/.ssh/id_rsa' /etc/letsencrypt/archive letsencrypt@{{ hostname }}:/etc/letsencrypt/
rsync -lr -e 'ssh -i /home/letsencrypt/.ssh/id_rsa' /etc/letsencrypt/live letsencrypt@{{ hostname }}:/etc/letsencrypt/
{%- endfor %}

{{ webserver_start if webserver_start is defined else '' -}}
