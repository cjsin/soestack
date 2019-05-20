{%- with args = { 'deployment_type': 'grafana_container', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
