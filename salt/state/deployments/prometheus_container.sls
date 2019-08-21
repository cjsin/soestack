include:
    - accounts.prometheus

{%- with args = { 'deployment_type': 'prometheus_container' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
