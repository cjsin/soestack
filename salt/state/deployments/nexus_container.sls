{%- with args = { 'deployment_type': 'nexus_container' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
