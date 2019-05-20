#!stateconf yaml . jinja

{%- with args = { 'deployment_type': 'gitlab_baremetal', 'actions': ['auto'] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
