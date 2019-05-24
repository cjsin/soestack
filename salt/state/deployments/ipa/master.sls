#!stateconf yaml . jinja

{%- with args = { 'deployment_type': 'ipa_master', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}

{#- temporarily disabled for faster running of the above while debugging it #}
{%- if False %}

include:
    - deployments.managed_hosts

{%- else %}

{{sls}}.managed-hosts.temporarily-disabled:
    noop.notice

{%- endif %}
