{%- with args = { 'deployment_type': 'kibana_container' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
