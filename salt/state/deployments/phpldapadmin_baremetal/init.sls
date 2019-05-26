{%- with args = { 'deployment_type': 'phpldapadmin_baremetal', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
