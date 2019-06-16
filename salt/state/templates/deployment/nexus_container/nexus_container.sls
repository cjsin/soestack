{#
# This template expects the following vars:
#
#   - deployment_name
#   - deployment
#}
{%- if 'roles' in grains and 'nexus-server' in grains.roles %}
{%    include('templates/containerized_service/containerized_service.sls') with context %}
{%- endif %}

