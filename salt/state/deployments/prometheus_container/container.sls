{%- with args = { 'deployment_type': 'prometheus_container', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
