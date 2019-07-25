{%- with args = { 'deployment_type': 'logstash_container' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
