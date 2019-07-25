{%- with args = { 'deployment_type': 'simple_http' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
