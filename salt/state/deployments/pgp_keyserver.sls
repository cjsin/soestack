{%- with args = { 'deployment_type': 'pgp_keyserver' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
