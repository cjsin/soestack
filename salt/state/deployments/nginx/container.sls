{%- with args = { 'deployment_type': 'nginx_container', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
