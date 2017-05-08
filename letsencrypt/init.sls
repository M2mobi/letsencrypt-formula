# -*- coding: utf-8 -*-
# vim: ft=sls

include:
  - .config
  - .service
{% if salt['grains.get']('ec2_tags:hierarchy', '') != 'secondary' %}
  - .install
  - .domains
{% endif %}
