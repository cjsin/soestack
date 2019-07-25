{%- with args = { 'deployment_type': 'managed_hosts' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
