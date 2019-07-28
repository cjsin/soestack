#!stateconf yaml . jinja

include:
    # Make sure ipa client enrolment secret is distributed
    - secrets

{%- with args = { 'deployment_type': 'ipa' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}

