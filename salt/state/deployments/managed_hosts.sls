{%- with args = { 'deployment_type': 'managed_hosts', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
