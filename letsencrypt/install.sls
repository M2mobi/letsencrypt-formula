# -*- coding: utf-8 -*-
# vim: ft=sls
{%- from "letsencrypt/map.jinja" import letsencrypt with context %}

{#- Use empty default for `grains.osfinger`, which isn't available in all distros #}
{%- if letsencrypt.use_package and
       grains.osfinger|d('') == 'Amazon Linux-2' %}
{%-   set rhel_ver = '7' %}
letsencrypt_external_repo:
  pkgrepo.managed:
    - name: epel
    - humanname: Extra Packages for Enterprise Linux {{ rhel_ver }} - $basearch
    - mirrorlist: https://mirrors.fedoraproject.org/metalink?repo=epel-{{ rhel_ver }}&arch=$basearch
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-{{ rhel_ver }}
    - failovermethod: priority
    - require_in:
      - pkg: letsencrypt-client
{%- endif %}

letsencrypt-client:
  {%- if letsencrypt.use_package %}
  pkg.installed:
    - pkgs: {{ letsencrypt.pkgs | json }}
  {%- else %}
  pkg.installed:
    - name: git
  {%-   if letsencrypt.version is defined and letsencrypt.version|length %}
  # Note: `git.cloned` is unavailable in `2017.7`
  git.cloned:
    - name: https://github.com/certbot/certbot
    - branch: {{ letsencrypt.version }}
    - target: {{ letsencrypt.cli_install_dir }}
  {%-   else %}
  git.latest:
    - name: https://github.com/certbot/certbot
    - target: {{ letsencrypt.cli_install_dir }}
    - force_reset: True
  {%-   endif %}
  {%- endif %}
    - reload_modules: True
