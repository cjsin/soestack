{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config %}
{%- set action = args.action if 'action' in args else 'all' %}

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'node_exporter' in pillar.svd.cots %}
{%-     set version = pillar.svd.cots.node_exporter.version %}
{%-     set hash    = pillar.svd.cots.node_exporter.hash %}

{%-     if action in [ 'all', 'install' ] %}

.install:
    archive.extracted:
        - name:             /opt
        - source:           {{pillar.nexus.urls.github}}/prometheus/node_exporter/releases/download/v{{version}}/node_exporter-{{version}}.linux-amd64.tar.gz
        - if_missing:       /opt/node_exporter-{{version}}-linux-amd64
        - user:             root
        - group:            root
        - trim_output:      10
        - enforce_toplevel: True
        - source_hash:      {{hash}}

.symlink-dir:
    file.symlink:
        - name:     /opt/node_exporter
        - target:   /opt/node_exporter-{{version}}.linux-amd64

.symlink-executable:
    file.symlink:
        - name:     /usr/local/bin/node_exporter
        - target:   /opt/node_exporter/node_exporter

{%-     endif %}

{%-     if action in [ 'all', 'configure' ] %}

include:
    - accounts.node_exporter

# A salt bug requires this comment here (without a comment, it appends an 'f' to the line above)

{%-     endif %}

{%-     if action in [ 'all', 'activate'] %}
 
{%-         set activated = 'activated' in deployment and deployment.activated %}

node-exporter-service:
    service.{{'running' if activated else 'dead'}}:
        - name: node_exporter
        - enable: {{activated}} 

{%-     endif %}

{#- # end if in svd #}
{%- endif %}
