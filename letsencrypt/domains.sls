# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

{% if salt['pillar.get']('letsencrypt:use_package', '') == true %}
  {% set letsencrypt_command = "letsencrypt" %}
{% else %}
  {% set letsencrypt_command = letsencrypt.cli_install_dir + "/letsencrypt-auto" %}
{% endif %}

{% set check_letsencrypt_cert = "/usr/local/bin/check_letsencrypt_cert.sh" %}
{% set obtain_letsencrypt_cert  = "/usr/local/bin/obtain_letsencrypt_cert.sh" %}

check-letsencrypt-cert:
  file.managed:
    - name: {{ check_letsencrypt_cert }}
    - mode: 755
    - source: salt://letsencrypt/files/check_letsencrypt_cert.sh

obtain-letsencrypt-cert:
  file.managed:
    - name: {{ obtain_letsencrypt_cert }}
    - mode: 755
    - template: jinja
    - source: salt://letsencrypt/files/obtain_letsencrypt_cert.sh
    - context:
      letsencrypt_command: {{ letsencrypt_command }}
      start_server: {{ letsencrypt.server.start if (letsencrypt.server is defined and letsencrypt.server.start is defined) else '' }}
      stop_server: {{ letsencrypt.server.stop if (letsencrypt.server is defined and letsencrypt.server.stop is defined) else '' }}

{%
  for setname, domainlist in salt['pillar.get'](
    'letsencrypt:domainsets'
  ).iteritems()
%}

create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}:
  cmd.run:
    - unless: {{ check_letsencrypt_cert }} {{ domainlist|join(' ') }}
    - name: {{ obtain_letsencrypt_cert }} {{ domainlist|join(' ') }}
    - require:
      - file: letsencrypt-config
      - file: check-letsencrypt-cert
      - file: obtain-letsencrypt-cert

letsencrypt-crontab-{{ setname }}-{{ domainlist[0] }}:
  cron.present:
    - name: {{ check_letsencrypt_cert }} {{ domainlist|join(' ') }} > /dev/null || {{ obtain_letsencrypt_cert }} {{ domainlist|join(' ') }}
    - month: '*'
    - minute: {{ letsencrypt.cron.minute }}
    - hour: {{ letsencrypt.cron.hour }}
    - dayweek: '*'
    - identifier: letsencrypt-{{ setname }}-{{ domainlist[0] }}
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}

{% endfor %}
