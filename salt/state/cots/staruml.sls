#!stateconf yaml . jinja

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'staruml' in pillar.svd.cots %}
{%-     set svd       = pillar.svd.cots.staruml %}
{%-     set version   = svd.version %}
{%-     set hash      = svd.hash if 'hash' in svd and svd.hash else '' %}

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
