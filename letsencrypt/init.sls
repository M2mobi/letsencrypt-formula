# -*- coding: utf-8 -*-
# vim: ft=sls

include:
  - letsencrypt.config
  - letsencrypt.service
{% if salt['grains.get']('ec2_tags:hierarchy', '') != 'secondary' %}
  - letsencrypt.install
  - letsencrypt.domains
{% endif %}
