#!stateconf yaml . jinja

{%- if 'versions' in pillar and 'cots' in pillar.versions and 'drawio' in pillar.versions.cots %}
{%-     set versions     = pillar.versions.cots.drawio %}
{%-     set version = versions.version %}
{%-     set hash    = versions.hash if 'hash' in versions and versions.hash else '' %}

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
