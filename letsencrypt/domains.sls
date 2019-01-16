# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

{% if letsencrypt.use_wrapper %}
  {% set check_cert_cmd = '/usr/local/bin/check_letsencrypt_cert.sh' %}
  {% set renew_cert_cmd = '/usr/local/bin/renew_letsencrypt_cert.sh' %}
  {% set create_cert_cmd = '/usr/local/bin/obtain_letsencrypt_cert.sh' %}
  {% set letsencrypt_cronjob  = "/usr/local/bin/letsencrypt_cronjob.sh" %}
  {% set old_check_cert_cmd_state = 'managed' %}
  {% set old_renew_cert_cmd_state = 'managed' %}
  {% set old_obtain_cert_cmd_state = 'managed' %}
  {% set old_cron_state = 'present' %}
{% else %}
  {% set check_cert_cmd = letsencrypt._cli_path ~ ' renew --dry-run --no-random-sleep-on-renew --cert-name' %}
  {% set renew_cert_cmd = letsencrypt._cli_path ~ ' renew' %}
  {% set create_cert_cmd = letsencrypt._cli_path %}
  {% set letsencrypt_cronjob  = "/usr/local/bin/letsencrypt_cronjob.sh" %}
  {% set old_check_cert_cmd_state = 'absent' %}
  {% set old_renew_cert_cmd_state = 'absent' %}
  {% set old_obtain_cert_cmd_state = 'absent' %}
  {% set old_cron_state = 'absent' %}
{% endif %}

{% if letsencrypt.use_wrapper %}
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
    - source: salt://letsencrypt/files/obtain_letsencrypt_cert.sh.jinja
{% endif %}

{% if letsencrypt.webroot != False %}
letsencrypt-webroot:
  file.directory:
    - name: {{ webroot.path }}/.well-known
    - user: root
    - group: root
    - mode: 755
{% endif %}

{% for setname, domainlist in letsencrypt.domainsets.items() %}
# domainlist[0] represents the "CommonName", and the rest
# represent SubjectAlternativeNames
create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}:
  cmd.run:
    - unless: {{ check_cert_cmd }} {{ domainlist[0] }}
{% if letsencrypt.use_wrapper %}
    - name: {{ create_cert_cmd }} {{ domainlist|join(' ') }}
{% else %}
    - name: {{ create_cert_cmd }} {{ letsencrypt.create_init_cert_subcmd }} --quiet --cert-name {{ setname }} -d {{ domainlist|join(' -d ') }} --non-interactive
      {% if not letsencrypt.use_package %}
    - cwd: {{ letsencrypt.cli_install_dir }}
      {% endif %}
{% endif %}
    - require:
      {% if letsencrypt.use_package %}
      - pkg: letsencrypt-client
      {% else %}
      - file: {{ check_cert_cmd }}
      {% endif %}
      - file: letsencrypt-config
{% if letsencrypt.use_wrapper %}
      - file: {{ check_cert_cmd }}
      - file: {{ obtain_cert_cmd }}
{% endif %}
{% if letsencrypt.webroot != False %}
      - file: letsencrypt-webroot
{% endif %}
    - require_in:
      - file: letsencrypt-crontab

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

create-fullchain-privkey-pem-for-{{ setname }}:
  cmd.run:
    - name: |
        cat {{ letsencrypt.config_dir.path }}/live/{{ setname }}/fullchain.pem \
            {{ letsencrypt.config_dir.path }}/live/{{ setname }}/privkey.pem \
            > {{ letsencrypt.config_dir.path }}/live/{{ setname }}/fullchain-privkey.pem && \
        chmod 600 {{ letsencrypt.config_dir.path }}/live/{{ setname }}/fullchain-privkey.pem
    - creates: {{ letsencrypt.config_dir.path }}/live/{{ setname }}/fullchain-privkey.pem
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist | join('+') }}

{% endfor %}

letsencrypt-cronjob:
  file.managed:
    - name: {{ letsencrypt_cronjob }}
    - mode: 755
    - template: jinja
    - source: salt://letsencrypt/files/letsencrypt_cronjob.sh.jinja

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
