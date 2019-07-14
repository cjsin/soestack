{%- with args = { 'deployment_type': 'pgp_keyserver', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
