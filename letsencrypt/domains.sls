# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

{% if salt['pillar.get']('letsencrypt:use_package', '') == true %}
  {% set letsencrypt_command = "letsencrypt" %}
{% else %}
  {% set letsencrypt_command = letsencrypt.cli_install_dir + "/letsencrypt-auto" %}
{% endif %}

{% set letsencrypt_check_cert = "/usr/local/bin/letsencrypt_check_cert.sh" %}
{% set letsencrypt_obtain_cert  = "/usr/local/bin/letsencrypt_obtain_cert.sh" %}
{% set letsencrypt_cronjob  = "/usr/local/bin/letsencrypt_cronjob.sh" %}
{% set domainsets = salt['pillar.get']('letsencrypt:domainsets') %}

letsencrypt-check-cert:
  file.managed:
    - name: {{ letsencrypt_check_cert }}
    - mode: 755
    - source: salt://letsencrypt/files/letsencrypt_check_cert.sh

letsencrypt-obtain-cert:
  file.managed:
    - name: {{ letsencrypt_obtain_cert }}
    - mode: 755
    - template: jinja
    - source: salt://letsencrypt/files/letsencrypt_obtain_cert.sh
    - context:
      letsencrypt_command: {{ letsencrypt_command }}

{% if letsencrypt.webserver is defined %}
webserver-dead:
  service.dead:
    - name: {{ letsencrypt.webserver.name }}

webserver-running:
  service.running:
    - name: {{ letsencrypt.webserver.name }}
    - require:
      - service: webserver-dead
{% endif %}

{% for setname, domainlist in domainsets.iteritems() %}

create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}:
  cmd.run:
    - unless: {{ letsencrypt_check_cert }} {{ domainlist|join(' ') }}
    - name: {{ letsencrypt_obtain_cert }} {{ domainlist|join(' ') }}
    - require:
      - file: letsencrypt-config
      - file: letsencrypt-check-cert
      - file: letsencrypt-obtain-cert
{% if letsencrypt.webserver is defined %}
      - service: webserver-dead
{% endif %}
    - require_in:
      - file: letsencrypt-crontab
{% if letsencrypt.webserver is defined %}
      - service: webserver-running
{% endif %}

{% endfor %}

letsencrypt-cronjob:
  file.managed:
    - name: {{ letsencrypt_cronjob }}
    - mode: 755
    - template: jinja
    - source: salt://letsencrypt/files/letsencrypt_cronjob.sh
    - context:
      letsencrypt_check_cert: {{ letsencrypt_check_cert }}
      letsencrypt_obtain_cert: {{ letsencrypt_obtain_cert }}
      domainsets: {{ domainsets }}
{% if letsencrypt.webserver is defined %}
      webserver_start: {{ letsencrypt.webserver.start }}
      webserver_stop: {{ letsencrypt.webserver.stop }}
{% endif %}

letsencrypt-crontab:
  cron.present:
    - name: {{ letsencrypt_cronjob }}
    - month: '*'
    - minute: {{ letsencrypt.cron.minute }}
    - hour: {{ letsencrypt.cron.hour }}
    - dayweek: '*'
    - identifier: letsencrypt-cronjob
