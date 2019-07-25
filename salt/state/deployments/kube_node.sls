{%- with args = { 'deployment_type': 'kube_node' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
