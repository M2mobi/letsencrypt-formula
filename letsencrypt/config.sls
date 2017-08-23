# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

letsencrypt-config-directory:
  file.directory:
    - name: /etc/letsencrypt
    - user: {{ letsencrypt.config_permissions.user }}
    - group: {{ letsencrypt.config_permissions.group }}

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
    - name: /etc/letsencrypt/cli.ini
    - makedirs: true
    - contents_pillar: letsencrypt:config
