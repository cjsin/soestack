{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config %}
{%- set action = args.action if 'action' in args else 'all' %}

{%- if 'versions' in pillar and 'cots' in pillar.versions and 'node_exporter' in pillar.versions.cots %}
{%-     set version = pillar.versions.cots.node_exporter.version %}
{%-     set hash    = pillar.versions.cots.node_exporter.hash %}

{%-     if action in [ 'all', 'install' ] %}

{{sls}}.node_exporter_baremetal.install:
    archive.extracted:
        - name:             /opt
        - source:           {{pillar.nexus.urls.github}}/prometheus/node_exporter/releases/download/v{{version}}/node_exporter-{{version}}.linux-amd64.tar.gz
        - if_missing:       /opt/node_exporter-{{version}}-linux-amd64
        - user:             root
        - group:            root
        - trim_output:      10
        - enforce_toplevel: True
        - source_hash:      {{hash}}

{{sls}}.node_exporter_baremetal.symlink-dir:
    file.symlink:
        - name:     /opt/node_exporter
        - target:   /opt/node_exporter-{{version}}.linux-amd64

{{sls}}.node_exporter_baremetal.symlink-executable:
    file.symlink:
        - name:     /usr/local/bin/node_exporter
        - target:   /opt/node_exporter/node_exporter

{%-     endif %}

{%-     if action in [ 'all', 'configure' ] %}

include:
    - accounts.node_exporter

{%-         if 'textfile_directory' in config and config.textfile_directory %}

{{sls}}.node_exporter_baremetal.textfile-collector-dir:
    file.directory:
        - name:   {{config.textfile_directory}}
        - user:   root
        - group:  root
        - mode:   '0755'
        - makedirs: True

{%-         endif %}

{%-     endif %}

# These are done by the nugget deployment
{# 
{{sls}}.node_exporter_baremetal.{{deployment_name}}-{{action}}.sysconfig:
    file.managed:
        - name:     /etc/sysconfig/node_exporter
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://templates/deployment/node_exporter_baremetal/sysconfig.jinja
        - template: jinja
        - context:
            config:  {{config|json}}

{{sls}}.node_exporter_baremetal.{{deployment_name}}-{{action}}.service-unit:
    file.managed:
        - name:     /etc/systemd/system/node_exporter.service
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://templates/deployment/node_exporter_baremetal/service.jinja #}


{%-     if action in [ 'all', 'activate'] %}
 
{%-         set activated = 'activated' in deployment and deployment.activated %}

{{sls}}.node_exporter_baremetal.node-exporter-service:
    service.{{'running' if activated else 'dead'}}:
        - name: node_exporter
        - enable: {{activated}} 

{%-     endif %}

{#- # end if in  pillar versions #}
{%- endif %}
