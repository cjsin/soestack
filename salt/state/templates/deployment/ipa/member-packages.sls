{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set node_type       = config.type if 'type' in config else 'client' %}
{%- set client_or_server = 'server' if node_type in ['server', 'master', 'replica'] else 'client' %}
{%- set package_set_name = 'ipa-' ~ client_or_server %}

{#- install required packages #}
{%- with args = { 'package_set_name': package_set_name } %}
{%      include('templates/package/sets.sls') with context %}
{%- endwith %}
