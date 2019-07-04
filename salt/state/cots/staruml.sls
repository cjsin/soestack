#!stateconf yaml . jinja

{%- if 'versions' in pillar and 'cots' in pillar.versions and 'staruml' in pillar.versions.cots %}
{%-     set versions       = pillar.versions.cots.staruml %}
{%-     set version   = versions.version %}
{%-     set hash      = versions.hash if 'hash' in versions and versions.hash else '' %}

{%-     if 'interwebs' in pillar.nexus.urls %}
{%-         set baseurl = pillar.nexus.urls['interwebs'] %}


.:
    file.managed:
        - name:     /opt/bin/StarUML
        - makedirs: True
        - source:   staruml: {{baseurl}}/s3.amazonaws.com/staruml-bucket/releases/StarUML-{{version}}-x86_64.AppImage
        - user:     root
        - group:    root
        - mode:     755

{%-     endif %}
{%- endif %}
