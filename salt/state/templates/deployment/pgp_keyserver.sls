{%- import 'lib/noop.sls' as noop %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set deployment_type = args.deployment_type %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set prefix          = 'pgp-server-deployment-' ~ deployment_name %}
{%- set action = args.action if 'action' in args else 'all' %}

{#- NOTE that these are activated here not in the nugget because #}
{#- this particular service needs to be initialised the first time #}

{%- if action in [ 'all', 'activate' ] %}
{%-     set activated = 'activated' in deployment and deployment.activated %}
{%-     for svc in [ 'sks-db', 'sks-recon' ] %}

{{sls}}.pgp_keyserver.{{prefix}}services.{{svc}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{svc}}
        - enable: {{activated}} 

{%-     endfor %}
{%- endif %}


