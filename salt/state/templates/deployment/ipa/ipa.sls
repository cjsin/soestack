{%- set deployment_name  = args.deployment_name %}
{%- set deployment       = args.deployment %}
{%- set config           = deployment.config if 'config' in deployment else {} %}
{%- set node_type        = config.type if 'type' in config else 'client' %}
{%- set client_or_server = 'server' if node_type in [ 'server', 'master', 'replica' ] else 'client' %}
{%- set templates        = 'templates/deployment/ipa' %}
{%- set action           = args.action if 'action' in args else 'all' %}

{%- if action in [ 'all', 'install' ] %}

{%      include(templates ~ '/member-packages.sls') with context %}

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{%      include(templates ~ '/member-scripts.sls') with context %}

{%-     if node_type in [ 'master' ] %}
{%          include(templates ~ '/master-pwgen.sls') with context %}
{%-     endif %}

{%-     if node_type in [ 'master', 'replica' ] %}
{%          include(templates ~ '/server-configure.sls') with context %}
{%-     endif %}

{%      include(templates ~ '/member-deploy.sls') with context %}

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}

{%-     if node_type in [ 'master', 'replica '] %}
{%          include(templates ~ '/server-activation.sls') with context %}
{%-     endif %}

{%-     if node_type in [ 'master' ] %}
{%-         include(templates ~ '/master-postinstall.sls') with context %}
{%-     endif %}

{%- endif %}

