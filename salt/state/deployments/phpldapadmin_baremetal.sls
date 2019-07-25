{%- with args = { 'deployment_type': 'phpldapadmin_baremetal' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
