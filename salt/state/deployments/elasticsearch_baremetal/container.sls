{%- with args = { 'deployment_type': 'elasticsearch_container', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
