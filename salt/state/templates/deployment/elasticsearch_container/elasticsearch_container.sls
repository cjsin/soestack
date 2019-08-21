{#
# This template expects the following vars:
#  args: a dict with the following keys:
#     - deployment_name   - the name of the deployment
#     - deployment        - the deployment object (should contain a container object)
#
#  an args containing the deployment and deployment_name is required
#}

{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set action          = args.action if 'action' in args else 'all' %}

{%- if action in [ 'all', 'configure' ] %}
{%-     if 'activated' in deployment and deployment.activated %}

# This service is a standard containerized service, however it will fail
# without the right sysctl values, so make sure sysctls are reloaded prior to activation
{{sls}}.{{action}}.reload-sysctls:
    cmd.run:
        - name: sysctl --system

{%-     endif %}
{%- endif %}

