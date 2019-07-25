{%- with args = { 'deployment_type': 'elasticsearch_container' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
