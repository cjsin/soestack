{#
#
# This template expects the following vars:
#  args: a dict with the following keys:
#     - deployment_name   - the name of the deployment
#     - deployment        - the deployment object (should contain a container object)
#
#  an args containing the deployment and deployment_name is required
#}

{%- set deployment_name = args.deployment_name %}
{%- set deployment_type = args.deployment_type %}
{%- set deployment      = args.deployment %}
{%- set deployment_args = args %}
{%- set action          = args.action if 'action' in args else ['auto'] %}

# This service is a standard containerized service, however it will fail
# without the right sysctl values, so make sure sysctls are reloaded prior to activation
{%- if action in [ 'all', 'configure' ] %}

{{sls}}.{{action}}.reload-sysctls:
    cmd.run:
        - name: sysctl --system

{%- endif %}

{%  include('templates/containerized_service/containerized_service.sls') with context %}

