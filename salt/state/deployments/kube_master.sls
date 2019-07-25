{%- with args = { 'deployment_type': 'kube_master' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
