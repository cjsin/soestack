#!stateconf yaml . jinja

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'drawio' in pillar.svd.cots %}
{%-     set svd     = pillar.svd.cots.drawio %}
{%-     set version = svd.version %}
{%-     set hash    = svd.hash if 'hash' in svd and svd.hash else '' %}

{%-     if 'github' in pillar.nexus.urls %}
{%-         set baseurl = pillar.nexus.urls['github'] %}

.install-requirements:
    pkg.installed:
        - pkgs:
            - libnotify
            - libappindicator
            - libXScrnSaver 

.install-drawio:
    pkg.installed:
        - sources: 
            - draw.io: '{{baseurl}}/jgraph/drawio-desktop/releases/download/v{{version}}/draw.io-x86_64-{{version}}.rpm'

{%-     endif %}
{%- endif %}
