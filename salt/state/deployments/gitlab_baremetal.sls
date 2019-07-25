{%- with args = { 'deployment_type': 'gitlab_baremetal' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
