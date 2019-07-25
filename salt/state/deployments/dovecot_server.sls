{%- with args = { 'deployment_type': 'dovecot_server' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
