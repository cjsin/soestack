{%- with args = { 'deployment_type': 'nexus_container', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
