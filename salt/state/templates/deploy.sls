{%- set deployment = args.deployment if 'deployment' in args else {} %}
{%- set deployment_name = args.deployment_name if 'deployment_name' in args else '' %}
{%- set deployment_type = args.deployment_type if 'deployment_type' in args else '' %}
{%- set typename        = args.deploy_class if 'deploy_class' in args else deployment_type %}
{%- set pillar_location = args.pillar_location if 'pillar_location' in args else '' %}
{%- set recursion_count = args.recursion if 'recursion' in args else 0 %}
{%- set diagnostics = False %}

{%- if deployment and deployment_name and deployment_type and typename and recursion_count < 4 %}
{%-     set action     = args.action if 'action' in args else '' %}

{%-     set default_typedata  = { 'isa': 'nugget', 'impl': 'templates/deployments/nugget.sls' } %}
{%-     set type_lookup       = pillar['deployment-types'] if 'deployment-types' in pillar else {} %}
{%-     set typedata_defaults = type_lookup.defaults if 'defaults' in type_lookup else  default_typedata %}
{%-     set typedata_specific = type_lookup[typename] if typename in type_lookup else {} %}
{%-     set typedata          = {} %}
{%-     do  typedata.update(typedata_defaults) %}
{%-     do  typedata.update(typedata_specific) %}
{%-     set superclass        = typedata['isa'] if 'isa' in typedata else '' %}
{%-     set prefix, suffix  = salt.uuids.ids(args) %}
 
{%-    if superclass %}
{#-     recurse to the superclass #}
{%-         set new_args = {} %}
{%-         do  new_args.update(args) %}
{%-         do  new_args.update({ 'deployment': deployment, 'deployment_type': deployment_type, 'deploy_class': superclass }) %}
{%-         do new_args.update({'recursion': recursion_count+1}) %}
{%-         with args = new_args %}

{%- if diagnostics %}
{{sls}}.deploying.{{deployment_name}}.recurse-for-superclass-of-{{typename}}={{superclass}}.{{action}}{{suffix}}:
    noop.notice:
        - text: |
            new args = {{args|json}}
{%- endif %}

{%              include('templates/deploy.sls') with context %}
{%-         endwith %}
{%-     endif %}

{%-     if 'impl' in typedata and typedata['impl'] not in ['','none','inherit','super'] %}
{%-         set impl = typedata['impl'].replace('%',typename).replace('.','/') ~ '.sls' %}

{%-         if diagnostics %}
{{sls}}.deploying.{{deployment_name}}.{{action}}.implementation-{{impl}}-{{suffix}}:
    noop.notice:
        - text: |
            Running {{impl}}
{%-         endif %}

{%-         set impl_args = {} %}
{%-         do impl_args.update(args) %}
{%-         do impl_args.update({'template': impl}) %}
{%-         with args = impl_args %}
{%              include(impl) with context %}
{%-         endwith %}
{%-     endif %}
{%- endif %}
