#!stateconf yaml . jinja

{%- with args = { 'deployment_type': 'grafana_container' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
