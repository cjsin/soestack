{%- set deployment_type  = args.deployment_type %}
{%- set deployment_name  = args.deployment_name %}
{%- set deployment       = args.deployment %}
{%- set pillar_location  = args.pillar_location if 'pillar_location' in args else ':'.join(['deployments',deployment_name]) %}
{%- set action           = args.action if 'action' in args else 'all' %}
{%- set diagnostics = False %}

{#- # Install the base nugget class - that has a name matching the deployment type #}
{%- set base_nugget_type = deployment_type.replace('_','-') %}

{%- if diagnostics %}
{{sls}}.{{deployment_name}}.{{action}}.base-nugget-type.{{base_nugget_type}}:
    noop.notice
{%- endif %}

{%- if 'nuggets' in pillar and pillar.nuggets and base_nugget_type in pillar.nuggets %}

{%-     if diagnostics %}
{{noop.notice(' '.join(['deployment', deployment_type, deployment_name, action, action~'-base-nugget', base_nugget_type])) }}
{%-     endif %}

{%-     with args = { 'nugget_name': base_nugget_type} %}
{%-        if diagnostics %}
{{sls}}.{{deployment_name}}.{{action}}.base-nugget-type.{{base_nugget_type}}-{{action}}:
    noop.notice
{%-        endif %}
{%         include('templates/nugget/'~action~'.sls') with context %}
{%-     endwith %}

{%- elif diagnostics %}
{{sls}}.{{deployment_name}}.{{action}}.base-nugget-type.{{base_nugget_type}}-{{action}}--no-nuggets-or-base-nugget-type-{{base_nugget_type}}-not-in-nuggets:
    noop.notice
{%- endif %}

{#- # Install this deployment as a nugget itself #}
{%- with args = { 'nugget': deployment, 
                  'nugget_name': '-'.join([deployment_type,'deployment',deployment_name]), 
                  'pillar_location': pillar_location, 
                  'action': action 
                } %}

{#- consider what this will do when action is 'all' #}
{%-     if diagnostics %}
{{noop.notice(' '.join(['deployment', deployment_type, deployment_name,action,'install-instance-as-nugget'])) }}
{%-     endif %}

{%      include('templates/nugget/'~action~'.sls') with context %}
{%- endwith %}
