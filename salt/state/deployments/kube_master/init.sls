{%- with args = { 'deployment_type': 'kube_master', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
