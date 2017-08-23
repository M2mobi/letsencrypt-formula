# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

letsencrypt-config-directory:
  file.directory:
    - name: {{ letsencrypt.config_dir.path }}
    - user: {{ letsencrypt.config_dir.user }}
    - group: {{ letsencrypt.config_dir.group }}
    - dir_mode: {{ letsencrypt.config_dir.mode }}

letsencrypt-archive-directory:
  file.directory:
    - name: /etc/letsencrypt/archive
    - user: {{ letsencrypt.config_permissions.user }}
    - group: {{ letsencrypt.config_permissions.group }}

letsencrypt-live-directory:
  file.directory:
    - name: /etc/letsencrypt/live
    - user: {{ letsencrypt.config_permissions.user }}
    - group: {{ letsencrypt.config_permissions.group }}

letsencrypt-config:
  file.managed:
    - name: {{ letsencrypt.config_dir.path }}/cli.ini
    - user: {{ letsencrypt.config_dir.user }}
    - group: {{ letsencrypt.config_dir.group }}
    - makedirs: true
    - contents_pillar: letsencrypt:config
