{%- with args = { 'deployment_type': 'simple_http', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
