{%- with args = { 'deployment_type': 'node_exporter_baremetal' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
