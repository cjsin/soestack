{%- with args = { 'deployment_type': 'gitlab_runner_baremetal' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
