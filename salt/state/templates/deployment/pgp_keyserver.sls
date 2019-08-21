{%- import 'lib/noop.sls' as noop %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set deployment_type = args.deployment_type %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set prefix          = 'pgp-server-deployment-' ~ deployment_name %}
{%- set action = args.action if 'action' in args else 'all' %}

{#- NOTE that these are activated here not in the nugget because #}
{#- this particular service needs to be initialised the first time #}
{%- if action in [ 'all', 'configure' ] %}

# The nginx service uses the pgp keyserver port also
{{sls}}.{{deployment_type}}.{{deployment_name}}.selinux-ports-{{action}}:
    selinux.port_policy_present:
        - name: tcp/11371
        - sel_type: http_port_t

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}
{%-     set activated = 'activated' in deployment and deployment.activated %}
{%-     for svc in [ 'sks-db', 'sks-recon', 'sks-web' ] %}

{{sls}}.pgp_keyserver.{{prefix}}services.{{svc}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{svc}}
        - enable: {{activated}} 

{%-     endfor %}
{%- endif %}


