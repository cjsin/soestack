{%- with args = { 'deployment_type': 'logstash_baremetal', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
