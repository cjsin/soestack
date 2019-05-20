#
# This template expects the following vars:
#  args: a dict with the following keys:
#     - deployment_name   - the name of the deployment
#     - deployment        - the deployment object (should contain a container object)
#
#  an args containing the deployment and deployment_name is required
{%  include('templates/containerized_service/containerized_service.sls') with context %}

