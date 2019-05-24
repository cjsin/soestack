{%- with args = { 'deployment_type': 'pxeboot_server', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
