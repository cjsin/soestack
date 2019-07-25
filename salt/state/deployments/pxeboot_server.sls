{%- with args = { 'deployment_type': 'pxeboot_server' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
