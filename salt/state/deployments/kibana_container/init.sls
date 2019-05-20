{%- with args = { 'deployment_type': 'kibana_container', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
