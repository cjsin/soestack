#!stateconf yaml . jinja

{%- with args = {'deployment_type': 'ipa_client' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}

include:
    # Make sure ipa client enrolment secret is distributed
    - secrets
    - deployments.managed_hosts
