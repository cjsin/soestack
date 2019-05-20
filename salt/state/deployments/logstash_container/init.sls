{%- with args = { 'deployment_type': 'logstash_container', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
