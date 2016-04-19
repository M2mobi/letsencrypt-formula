# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "letsencrypt/map.jinja" import letsencrypt with context %}

{% if salt['pillar.get']('letsencrypt:use_package', '') == true %}
letsencrypt-client-package:
  pkg.installed:
    - name: {{ letsencrypt.package }}
{% else %}
letsencrypt-client-git:
  git.latest:
    - name: https://github.com/letsencrypt/letsencrypt
    - target: {{ letsencrypt.cli_install_dir }}
{% endif %}
