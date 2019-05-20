{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}

{%- set deployment_type = args.deployment_type %}

# Nothing here yet - the managed host file is now done by the managed-hosts nugget
