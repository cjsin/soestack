
{%- with args = { 'deployment_type': 'grafana_baremetal' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
