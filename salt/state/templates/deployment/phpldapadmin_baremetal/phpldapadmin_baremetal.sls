{%- set suffix          = args.suffix if 'suffix' in args else salt['uuids.short']() %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment_type = args.deployment_type %}
{%- set deployment      = args.deployment %}
{%- set action           = args.action if 'action' in args else 'all' %}

{%- if action in [ 'all', 'install' ] %}

#{{sls}}.install-phpldapadmin-{{suffix}}:
#    pkg.installed:
#        - pkgs:
#            - phpldapadmin
#        # Speed up the salt pkg states by not initiating the install if it's already done
#        # because any pkg state causes salt to do a yum check-update
#        - unless: rpm -q phpldapadmin

{%- endif %}

{#- # This is disabled at the mo because it should be done by the nugget base class #}
{%- if False %}

{%-     if 'filesystem' in deployment and deployment.filesystem %}
{%-         with args = { 'parent': deployment.filesystem, 'pillar_location': 'deployments:' ~ deployment_name} %}
{%              include('templates/support/filesystem.sls') with context %}
{%-         endwith %}
{%-     endif %}

{%- endif %}
