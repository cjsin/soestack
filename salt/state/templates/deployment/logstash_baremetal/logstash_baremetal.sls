{%- set diagnostics      = False %}
{%- set prefix, suffix   = salt.uuids.ids(args) %}
{%- set deployment       = args.deployment %}
{%- set deployment_name  = args.deployment_name %}
{%- set deployment_type  = args.deployment_type %}
{%- set service_name     = deployment_name %}
{%- set filesystem       = deployment.filesystem if 'filesystem' in deployment else {} %}
{%- set pillar_location  = ':'.join(['deployments',deployment_name]) %}
{%- set state_tag        = deployment_type ~ '-' ~ deployment_name %}
{%- set action           = args.action if 'action' in args else 'all' %}
{%- set account_defaults = { 'user': 'logstash', 'group': 'logstash', 'extra_groups': [] } %}
{%- set account_info     = deployment.account if 'account' in deployment and deployment.account else account_defaults %}
{%- set user             = account_info.user if 'user' in account_info and account_info.user else 'logstash' %}
{%- set group            = account_info.group if 'group' in account_info and account_info.group else user %}

{%- if 'versions' in pillar and 'cots' in pillar.versions and 'logstash' in pillar.versions.cots %}
{%-     set version = pillar.versions.cots.logstash.version %}


{%-     if action in [ 'all', 'install' ] %}

{{sls}}.{{prefix}}{{state_tag}}-requirements{{suffix}}:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

{{sls}}.{{prefix}}{{state_tag}}-direct-download{{suffix}}:
    pkg.installed:
        - sources: 
            - logstash: {{pillar.nexus.urls.elasticsearch}}/downloads/logstash/logstash-{{version}}.rpm
        - hash:   {{pillar.versions.cots.logstash.hash}}

{%-     endif %}


{%-     if action in [ 'all', 'configure' ] %}

{%-         if 'extra_groups' in account_info and account_info.extra_groups %}
{%-             for extra_group in account_info.extra_groups %}

{{sls}}.{{prefix}}{{state_tag}}-user-{{user}}-group-{{extra_group}}{{suffix}}:
    cmd.run:
        - name:   usermod -a -G '{{extra_group}}' '{{user}}'
        - unless: groups '{{user}}' | egrep '(^|[[:space:]]){{extra_group}}([[:space:]]|$)' 

{%-             endfor %}
{%-         endif %}

{%-         set args = { 'parent': filesystem, 'pillar_location' : pillar_location } %}
{%          include('templates/support/filesystem.sls') with context %}

{{sls}}.{{prefix}}{{state_tag}}-service-unit{{suffix}}:
    file.managed:
        - name:     /etc/systemd/system/{{deployment_name}}.service
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://templates/deployment/logstash_baremetal/service.jinja
        - template: jinja
        - context:
            deployment_name: {{deployment_name}}
            user:            {{user}}
            group:           {{group}}

{%-     endif %}

{%-     if action in [ 'all', 'activate' ] %}

{%-         set activated = 'activated' in deployment and deployment.activated %}

{{sls}}.{{prefix}}{{state_tag}}-service{{suffix}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{deployment_name}}
        - enable: {{activated}} 

{%-     endif %}

{%- endif %}
