#!stateconf yaml . jinja

{%- with args = { 'deployment_type': 'gitlab_runner_baremetal', 'action': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
