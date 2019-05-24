{#
# This template expects the following vars:
#  args: a dict with the following keys:
#     - deployment_name   - the name of the deployment
#     - deployment        - the deployment object (should contain a container object)
#}

{%- set container = args.deployment.container %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment = args.deployment %}
{%- set config    = deployment.config if 'config' in deployment and deployment.config else {} %}

{%  include('templates/containerized_service/containerized_service.sls') with context %}

