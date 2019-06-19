#!stateconf yaml . jinja

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'pencil' in pillar.svd.cots %}
{%-     set svd       = pillar.svd.cots.pencil %}
{%-     set version   = svd.version.split('-') %}
{%-     set hash      = svd.hash if 'hash' in svd and svd.hash else '' %}
{%-     if 'interwebs' in pillar.nexus.urls %}
{%-         set baseurl = pillar.nexus.urls['interwebs'] %}

.install-pencil:
    pkg.installed:
        - sources: 
            - Pencil: '{{baseurl}}/pencil.evolus.vn/dl/V{{version[0]}}/Pencil-{{version[0]}}-{{version[1]}}.x86_64.rpm'

{%-     endif %}
{%- endif %}
