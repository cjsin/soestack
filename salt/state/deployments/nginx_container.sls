{%- with args = { 'deployment_type': 'nginx_container' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
