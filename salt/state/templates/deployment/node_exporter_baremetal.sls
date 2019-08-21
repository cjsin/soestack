{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config %}
{%- set action = args.action if 'action' in args else 'all' %}

{%-     if action in [ 'all', 'configure' ] %}

include:
    - accounts.node_exporter

# Note that other configuration is done by the deployment as a nugget and the nugget
# configuration defined within the pillar data for this deployment

{%- endif %}
