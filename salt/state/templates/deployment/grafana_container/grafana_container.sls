{#
#
# This template expects the following vars:
#  args: a dict with the following keys:
#     - deployment_name   - the name of the deployment
#     - deployment        - the deployment object (should contain a container object)
#
#}

{%- set deployment_name = args.deployment_name %}
{%- set deployment_type = args.deployment_type %}
{%- set deployment      = args.deployment %}
{%- set deployment_args = args %}
{%- set action          = args.action if 'action' in args else ['auto'] %}

{#- NOTE that this user account creation is performed in the install phase #}
{#- so that it will happen before the superclass (containerized_servic) configure phase #}

{%- if action in [ 'all', 'install' ] %}

{#-     # Salt fails to create the group and user with obscure incorrect errors #}
{%-     if False %}
{%-         with args = { 'user': 'grafana', 'uid': 472, 'group': 'grafana', 'gid': 472, 'home':'/usr/lib/grafana' } %}
{%              include('templates/account/usergroup.sls') with context %}
{%-         endwith %}
{%-     else %}

{{sls}}.{{deployment_name}}.{{action}}.user-group-setup:
    cmd.run:
        - name: |
            getent group grafana || groupadd -g 472 grafana
            getent passwd grafana || useradd -u 472 -d /var/lib/grafana -r -s /sbin/nologin -g 472 grafana 
        - unless: getent group grafana && getent passwd grafana
{%-     endif %}

{%- endif %}
