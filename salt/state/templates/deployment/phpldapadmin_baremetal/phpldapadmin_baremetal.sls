{%- set suffix          = args.suffix if 'suffix' in args else salt['uuids.short']() %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment_type = args.deployment_type %}
{%- set deployment      = args.deployment %}

{{sls}}.install-phpldapadmin-{{suffix}}:
    pkg.installed:
        - name:
            - phpldapadmin
        # Speed up the salt pkg states by not initiating the install if it's already done
        # because any pkg state causes salt to do a yum check-update
        - unless: rpm -q phpldapadmin

{%- if 'filesystem' in deployment and deployment.filesystem %}
{%-     with args = { 'parent': deployment.filesystem, 'pillar_location': 'deployments:'~deployment_type~':' ~ deployment_name} %}
{%          include('templates/support/filesystem.sls') with context %}
{%-     endwith %}
{%- endif %}
