{#
# This template expects the following vars:
#
#   - deployment_name
#   - deployment
#}

{%  include('templates/containerized_service/containerized_service.sls') with context %}

