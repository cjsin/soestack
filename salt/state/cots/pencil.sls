#!stateconf yaml . jinja

{%- if 'versions' in pillar and 'cots' in pillar.versions and 'pencil' in pillar.versions.cots %}
{%-     set versions  = pillar.versions.cots.pencil %}
{%-     set version   = versions.version.split('-') %}
{%-     set hash      = versions.hash if 'hash' in versions and versions.hash else '' %}
{%-     if 'interwebs' in pillar.nexus.urls %}
{%-         set baseurl = pillar.nexus.urls['interwebs'] %}

.install-pencil:
    pkg.installed:
        - sources: 
            - Pencil: '{{baseurl}}/pencil.evolus.vn/dl/V{{version[0]}}/Pencil-{{version[0]}}-{{version[1]}}.x86_64.rpm'

{%-     endif %}
{%- endif %}
