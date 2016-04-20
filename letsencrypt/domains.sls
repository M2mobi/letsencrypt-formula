# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

{% if letsencrypt.use_package %}
  # Renew checks if the cert exists and needs to be renewed
  {% set check_cert_cmd = '/usr/bin/certbot renew --dry-run --cert-name' %}
  {% set renew_cert_cmd = '/usr/bin/certbot renew' %}
  {% set old_check_cert_cmd_state = 'absent' %}
  {% set old_renew_cert_cmd_state = 'absent' %}
  {% set old_obtain_cert_cmd_state = 'absent' %}
  {% set old_cron_state = 'absent' %}
  {% set create_cert_cmd = '/usr/bin/certbot' %}
{% else %}
  {% set check_cert_cmd = '/usr/local/bin/check_letsencrypt_cert.sh' %}
  {% set renew_cert_cmd = '/usr/local/bin/renew_letsencrypt_cert.sh' %}
  {% set obtain_cert_cmd = '/usr/local/bin/obtain_letsencrypt_cert.sh' %}
  {% set old_check_cert_cmd_state = 'managed' %}
  {% set old_renew_cert_cmd_state = 'managed' %}
  {% set old_obtain_cert_cmd_state = 'managed' %}
  {% set old_cron_state = 'present' %}
  {% set create_cert_cmd = letsencrypt.cli_install_dir ~ '/letsencrypt-auto' %}
{% endif %}

{{ check_cert_cmd }}:
  file.{{ old_check_cert_cmd_state }}:
    - template: jinja
    - source: salt://letsencrypt/files/check_letsencrypt_cert.sh.jinja
    - mode: 755

{{ renew_cert_cmd }}:
  file.{{ old_renew_cert_cmd_state }}:
    - template: jinja
    - source: salt://letsencrypt/files/renew_letsencrypt_cert.sh.jinja
    - mode: 755
    - require:
      - file: {{ check_cert_cmd }}

{{ obtain_cert_cmd }}:
  file.{{ old_obtain_cert_cmd_state }}:
    - mode: 755
    - template: jinja
    - source: salt://letsencrypt/files/obtain_letsencrypt_cert.sh
    - context:
      letsencrypt_command: {{ letsencrypt_command }}
      start_server: {{ letsencrypt.server.start if (letsencrypt.server is defined and letsencrypt.server.start is defined) else '' }}
      stop_server: {{ letsencrypt.server.stop if (letsencrypt.server is defined and letsencrypt.server.stop is defined) else '' }}

{% for setname, domainlist in letsencrypt.domainsets.items() %}

# domainlist[0] represents the "CommonName", and the rest
# represent SubjectAlternativeNames
create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}:
  cmd.run:
    - unless: {{ check_cert_cmd }} {{ domainlist[0] }}
    - name: {{ obtain_cert_cmd }} {{ domainlist|join(' ') }}
    - require:
      {% if letsencrypt.use_package %}
      - pkg: letsencrypt-client
      {% else %}
      - file: {{ check_cert_cmd }}
      {% endif %}
      - file: letsencrypt-config
      - file: {{ check_cert_cmd }}
      - file: /usr/local/bin/obtain_letsencrypt_cert.sh

letsencrypt-crontab-{{ setname }}-{{ domainlist[0] }}:
  cron.{{ old_cron_state }}:
    - name: {{ renew_cert_cmd }} {{ domainlist|join(' ') }}
    - month: '*'
    - minute: '{{ letsencrypt.cron.minute }}'
    - hour: '{{ letsencrypt.cron.hour }}'
    - dayweek: '{{ letsencrypt.cron.dayweek }}'
    - identifier: letsencrypt-{{ setname }}-{{ domainlist[0] }}
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}
      {% if letsencrypt.use_package %}
      - pkg: letsencrypt-client
      {% else %}
      - file: {{ renew_cert_cmd }}
      {% endif %}

create-fullchain-privkey-pem-for-{{ domainlist[0] }}:
  cmd.run:
    - name: |
        cat {{ letsencrypt.config_dir.path }}/live/{{ domainlist[0] }}/fullchain.pem \
            {{ letsencrypt.config_dir.path }}/live/{{ domainlist[0] }}/privkey.pem \
            > {{ letsencrypt.config_dir.path }}/live/{{ domainlist[0] }}/fullchain-privkey.pem && \
        chmod 600 {{ letsencrypt.config_dir.path }}/live/{{ domainlist[0] }}/fullchain-privkey.pem
    - creates: {{ letsencrypt.config_dir.path }}/live/{{ domainlist[0] }}/fullchain-privkey.pem
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}

{% endfor %}
