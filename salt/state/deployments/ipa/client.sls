#!stateconf yaml . jinja

{%- with args = {'deployment_type': 'ipa_client' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}

include:
    - deployments.managed_hosts
