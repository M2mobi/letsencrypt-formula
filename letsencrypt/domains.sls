# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

{% set check_letsencrypt_cert = "/usr/local/bin/check_letsencrypt_cert.sh" %}
{% set renew_letsencrypt_cert  = "/usr/local/bin/renew_letsencrypt_cert.sh" %}
{% set obtain_letsencrypt_cert  = "/usr/local/bin/obtain_letsencrypt_cert.sh" %}
{% set letsencrypt_cronjob  = "/usr/local/bin/letsencrypt_cronjob.sh" %}
{% set domainsets = salt['pillar.get']('letsencrypt:domainsets') %}

{% if salt['pillar.get']('letsencrypt:use_package', '') == true %}
  {% set letsencrypt_command = "certbot" %}
{% else %}
  {% set letsencrypt_command = letsencrypt.cli_install_dir + "/letsencrypt-auto" %}
{% endif %}

/usr/local/bin/check_letsencrypt_cert.sh:
  file.managed:
    - mode: 755
    - source: salt://letsencrypt/files/check_letsencrypt_cert.sh

/usr/local/bin/renew_letsencrypt_cert.sh:
  file.managed:
    - template: jinja
    - source: salt://letsencrypt/files/renew_letsencrypt_cert.sh.jinja
    - mode: 755
    - require:
      - file: /usr/local/bin/check_letsencrypt_cert.sh

/usr/local/bin/obtain_letsencrypt_cert.sh:
  file.managed:
    - mode: 755
    - template: jinja
    - source: salt://letsencrypt/files/obtain_letsencrypt_cert.sh
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
    - unless: {{ check_letsencrypt_cert }} {{ domainlist|join(' ') }}
    - name: {{ obtain_letsencrypt_cert }} {{ domainlist|join(' ') }}
    - require:
      - file: letsencrypt-config
      - file: /usr/local/bin/check_letsencrypt_cert.sh
      - file: /usr/local/bin/obtain_letsencrypt_cert.sh
{% if letsencrypt.webserver is defined %}
      - service: webserver-dead
{% endif %}
    - require_in:
      - file: letsencrypt-crontab
{% if letsencrypt.webserver is defined %}
      - service: webserver-running
{% endif %}

create-fullchain-privkey-pem-for-{{ domainlist[0] }}:
  cmd.run:
    - name: |
        cat /etc/letsencrypt/live/{{ domainlist[0] }}/fullchain.pem \
            /etc/letsencrypt/live/{{ domainlist[0] }}/privkey.pem \
            > /etc/letsencrypt/live/{{ domainlist[0] }}/fullchain-privkey.pem && \
        chmod 600 /etc/letsencrypt/live/{{ domainlist[0] }}/fullchain-privkey.pem
    - creates: /etc/letsencrypt/live/{{ domainlist[0] }}/fullchain-privkey.pem
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}

{% endfor %}

letsencrypt-cronjob:
  file.managed:
    - name: {{ letsencrypt_cronjob }}
    - mode: 755
    - template: jinja
    - source: salt://letsencrypt/files/letsencrypt_cronjob.sh
    - context:
      renew_letsencrypt_cert: {{ renew_letsencrypt_cert }}
      domainsets: {{ domainsets }}
{% if letsencrypt.webserver is defined %}
      webserver_start: {{ letsencrypt.webserver.start }}
      webserver_stop: {{ letsencrypt.webserver.stop }}
{% endif %}

# domainlist[0] represents the "CommonName", and the rest
# represent SubjectAlternativeNames
letsencrypt-crontab:
  cron.present:
    - name: {{ letsencrypt_cronjob }}
    - month: '*'
    - minute: {{ letsencrypt.cron.minute }}
    - hour: {{ letsencrypt.cron.hour }}
{% if 'dayweek' in letsencrypt.cron %}
    - dayweek: {{ letsencrypt.cron.dayweek }}
{% else %}
    - dayweek: '*'
{% endif %}
    - identifier: letsencrypt-cronjob
