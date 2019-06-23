{%- set diagnostics      = False %}
{%- set prefix, suffix   = salt.uuid.ids(args) %}
{%- set deployment       = args.deployment %}
{%- set deployment_name  = args.deployment_name %}
{%- set deployment_type  = args.deployment_type %}
{%- set service_name     = deployment_name %}
{%- set service_suffix   = deployment_name %}
{%- set filesystem       = deployment.filesystem if 'filesystem' in deployment else {} %}
{%- set pillar_location  = ':'.join(['deployments',deployment_type,deployment_name]) %}
{%- set state_tag        = deployment_type ~ '-' ~ deployment_name %}
{%- set action           = args.action if 'action' in args else 'all' %}

{%- if action in [ 'all', 'install' ] %}

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{%-     set args = { 'parent': filesystem, 'pillar_location' : pillar_location } %}
{%      include('templates/support/filesystem.sls') with context %}

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}

{%-     set activated = 'activated' in deployment and deployment.activated %}

{{sls}}.{{prefix}}{{state_tag}}-service{{suffix}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   dovecot
        - enable: {{activated}} 

{%- endif %}
