# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

{% if salt['pillar.get']('letsencrypt:use_package', '') == true %}
  {% set letsencrypt_command = "letsencrypt" %}
{% else %}
  {% set letsencrypt_command = letsencrypt.cli_install_dir + "/letsencrypt-auto" %}
{% endif %}

check-letsencrypt-cert:
  file.managed:
    - name: /usr/local/bin/check_letsencrypt_cert.sh
    - mode: 755
    - source: salt://letsencrypt/files/check_letsencrypt_cert.sh

{%
  for setname, domainlist in salt['pillar.get'](
    'letsencrypt:domainsets'
  ).iteritems()
%}

create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}:
  cmd.run:
    - unless: /usr/local/bin/check_letsencrypt_cert.sh {{ domainlist|join(' ') }}
    - name: {{ letsencrypt_command }} -d {{ domainlist|join(' -d ') }} certonly
    - require:
      - file: letsencrypt-config
      - file: check-letsencrypt-cert

letsencrypt-crontab-{{ setname }}-{{ domainlist[0] }}:
  cron.present:
    - name: /usr/local/bin/check_letsencrypt_cert.sh {{ domainlist|join(' ') }} > /dev/null || {{ letsencrypt_command }} -d {{ domainlist|join(' -d ') }} certonly
    - month: '*'
    - minute: random
    - hour: random
    - dayweek: '*'
    - identifier: letsencrypt-{{ setname }}-{{ domainlist[0] }}
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}

{% endfor %}
