{%- with args = { 'deployment_type': 'elasticsearch_baremetal' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
