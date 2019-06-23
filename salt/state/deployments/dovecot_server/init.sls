{%- with args = { 'deployment_type': 'dovecot_server', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
