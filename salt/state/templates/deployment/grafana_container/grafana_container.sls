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

{%- if action in [ 'all', 'configure' ] %}
{%-     with args = { 'user': 'grafana', 'uid': 472, 'group': 'grafana', 'gid': 472, 'home':'/usr/lib/grafana' } %}
{%          include('templates/account/usergroup.sls') with context %}
{%-     endwith %}
{%- endif %}

{%- with args = deployment_args %}
{%      include('templates/containerized_service/containerized_service.sls') with context %}
{%- endwith %}
