# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

/usr/local/bin/check_letsencrypt_cert.sh:
  file.managed:
    - name: /usr/local/bin/check_letsencrypt_cert.sh
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
    - name: /usr/local/bin/obtain_letsencrypt_cert.sh
    - mode: 755
    - template: jinja
    - source: salt://letsencrypt/files/obtain_letsencrypt_cert.sh
    - context:
      letsencrypt_command: {{ letsencrypt_command }}
      start_server: {{ letsencrypt.server.start if (letsencrypt.server is defined and letsencrypt.server.start is defined) else '' }}
      stop_server: {{ letsencrypt.server.stop if (letsencrypt.server is defined and letsencrypt.server.stop is defined) else '' }}

{% if salt['pillar.get']('letsencrypt:use_package', '') == true %}
  {% set letsencrypt_command = "letsencrypt" %}
{% else %}
  {% set letsencrypt_command = letsencrypt.cli_install_dir + "/letsencrypt-auto" %}
{% endif %}

{%
  for setname, domainlist in salt['pillar.get'](
    'letsencrypt:domainsets'
  ).iteritems()
%}

create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}:
  cmd.run:
    - unless: /usr/local/bin/check_letsencrypt_cert.sh {{ domainlist|join(' ') }}
    - name: /usr/local/bin/obtain_letsencrypt_cert.sh {{ domainlist|join(' ') }}
    - require:
      - file: letsencrypt-config
      - file: /usr/local/bin/check_letsencrypt_cert.sh
      - file: /usr/local/bin/obtain_letsencrypt_cert.sh

# domainlist[0] represents the "CommonName", and the rest
# represent SubjectAlternativeNames
letsencrypt-crontab-{{ setname }}-{{ domainlist[0] }}:
  cron.present:
    - name: /usr/local/bin/renew_letsencrypt_cert.sh {{ domainlist|join(' ') }}
    - month: '*'
    - minute: random
    - hour: random
    - dayweek: '*'
    - identifier: letsencrypt-{{ setname }}-{{ domainlist[0] }}
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}
      - file: /usr/local/bin/renew_letsencrypt_cert.sh

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
