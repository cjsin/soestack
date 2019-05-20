
{%- with args = { 'deployment_type': 'grafana_baremetal', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
