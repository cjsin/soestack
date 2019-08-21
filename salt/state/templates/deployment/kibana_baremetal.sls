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
{%- set account_defaults = { 'user': 'kibana', 'group': 'kibana', 'extra_groups': [] } %}
{%- set account_info     = deployment.account if 'account' in deployment and deployment.account else account_defaults %}
{%- set user             = account_info.user if 'user' in account_info and account_info.user else 'kibana' %}
{%- set group            = account_info.group if 'group' in account_info and account_info.group else user %}

{%- if action in [ 'all', 'install' ] %}

{%-     if 'versions' in pillar and 'cots' in pillar.versions and 'kibana' in pillar.versions.cots %}
{%-         set version = pillar.versions.cots.kibana.version %}

{{sls}}.requirements:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

{{sls}}.kibana-direct-download:
    pkg.installed:
        - sources: 
            - kibana: {{pillar.nexus.urls.elasticsearch}}/downloads/kibana/kibana-{{version}}-x86_64.rpm
        - hash:   {{pillar.versions.cots.kibana.hash}}

{%-     endif %}
{%- endif %}
