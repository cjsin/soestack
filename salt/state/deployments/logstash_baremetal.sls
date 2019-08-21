{%- with args = { 'deployment_type': 'logstash_baremetal' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
