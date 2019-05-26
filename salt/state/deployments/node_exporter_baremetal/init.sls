{%- with args = { 'deployment_type': 'node_exporter_baremetal', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
