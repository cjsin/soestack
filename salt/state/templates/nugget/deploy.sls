{#- install/configure a deployment object as a nugget #}
{%- set nugget = args.deployment %}
{%- set nugget_name = 'deployment-' ~ args.deployment_name %}
{%- set pillar_location = args.pillar_location %}
{%- set action = args.action if 'action' in args else ['auto'] %}
{%- with args = { 'nugget': deployment, 
                  'nugget_name': '-'.join([deployment_type,'deployment',deployment_name]), 
                  'pillar_location': pillar_location, 
                  'action': action 
                } %}
{%      include('templates/nugget/'~action~'.sls') with context %}
{%- endwith %}
