{%- set diagnostics      = False %}
{%- set prefix, suffix   = salt.uuid.ids(args) %}
{%- set deployment       = args.deployment %}
{%- set deployment_name  = args.deployment_name %}
{%- set deployment_type  = args.deployment_type %}
{%- set service_name     = deployment_name %}
{%- set service_suffix   = deployment_name|replace('logstash-','') %}
{%- set filesystem       = deployment.filesystem if 'filesystem' in deployment else {} %}
{%- set pillar_location  = ':'.join(['deployments',deployment_type,deployment_name]) %}
{%- set state_tag        = deployment_type ~ '-' ~ deployment_name %}
{%- set action           = args.action if 'action' in args else 'all' %}
{%- set account_defaults = { 'user': 'logstash', 'group': 'logstsash', 'extra_groups': [] } %}
{%- set account_info     = deployment.account if 'account' in deployment and deployment.account else account_defaults %}
{%- set user             = account_info.user if 'user' in account_info and account_info.user else 'logstash' %}
{%- set group            = account_info.group if 'group' in account_info and account_info.group else user %}

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'logstash' in pillar.svd.cots %}
{%-     set version = pillar.svd.cots.logstash.version %}


{%-     if action in [ 'all', 'install' ] %}

{{prefix}}{{state_tag}}-requirements{{suffix}}:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

{{prefix}}{{state_tag}}-direct-download{{suffix}}:
    pkg.installed:
        - sources: 
            - logstash: http://nexus:7081/repository/elasticsearch/downloads/logstash/logstash-{{version}}.rpm
        - hash:   {{pillar.svd.cots.logstash.hash}}

{%-     endif %}


{%-     if action in [ 'all', 'configure' ] %}

{%-         if 'extra_groups' in account_info and account_info.extra_groups %}
{%-             for extra_group in account_info.extra_groups %}

{{prefix}}{{state_tag}}-user-{{user}}-group-{{extra_group}}{{suffix}}:
    cmd.run:
        - name:   usermod -a -G '{{extra_group}}' '{{user}}'
        - unless: groups '{{user}}' | egrep '(^|[[:space:]]){{extra_group}}([[:space:]]|$)' 

{%-             endfor %}
{%-         endif %}

{%-         set args = { 'parent': filesystem, 'pillar_location' : pillar_location } %}
{%          include('templates/support/filesystem.sls') with context %}

{{prefix}}{{state_tag}}-service-unit{{suffix}}:
    file.managed:
        - name:     /etc/systemd/system/{{deployment_name}}.service
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://templates/deployment/logstash_baremetal/service.jinja
        - template: jinja
        - context:
            service_suffix: {{service_suffix}}
            deployment_name: {{deployment_name}}
            user: {{user}}
            group: {{group}}

{%-     endif %}

{%-     if action in [ 'all', 'activate' ] %}

{%-         set activated = 'activated' in deployment and deployment.activated %}

{{prefix}}{{state_tag}}-service{{suffix}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   logstash-{{service_suffix}}
        - enable: {{activated}} 

{%-     endif %}

{%- endif %}
