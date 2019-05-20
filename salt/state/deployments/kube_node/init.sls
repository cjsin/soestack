{%- with args = { 'deployment_type': 'kube_node', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
