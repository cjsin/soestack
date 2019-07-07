{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'roles' in grains %}
    {{sls}}: {{grains.roles|json}}
    {%- else %}
    {{sls}}: 'no roles grain set yet'
    {%- endif %}

{#- # wtf, it seems slspath is not set at all while processing pillar data #}
{#- # so it is hard coded here for now, but should raise a bug or feature request with saltstack #}
{%- set slspath = 'layers' %}
{%- set prefix = '/' if slspath else '' %}

# attempted_load:
#     {{slspath ~ '/host/' ~ grains.host ~ '.sls'}}:

{%- set roles = grains.roles if 'roles' in grains and grains.roles else  ( grains.role if 'role' in grains and grains.role else []) %}
{%-     if False %}
{%- for role in roles %}
{%          include(slspath ~ prefix ~ 'role/' ~ role~ '.sls') ignore missing %}
{%- endfor %}
{%-     endif %}

{%- if True %}
{%-     if roles %}
{%-         set pwd = salt['cmd.run']('pwd') %}
{%-         set pillar_base = salt['config.get']('pillar_roots:base:0') %}
{%-         set found = [] %}
{%-         set not_found = [] %}
# - pillar base is {{pillar_base }}
{%          for r in roles %}
{%-             set role_sls = sls.replace('.','/') ~ '/'~r~ '.sls' %}
{%-             set f = pillar_base ~ '/' ~ role_sls %}
{%-             if salt['file.file_exists'](f) %}
{%-                 do found.append(sls ~'.'~r) %}
{%-             else %}
# - 'layers.role.{{r}} - {{f}} not found from {{pillar_base}}'
{%-                 do not_found.append([slspath,sls,r,f]) %}
{%              endif %}
{%-         endfor %}
{%-         if found %}

x-included:
    {%- for x in found %}
    - {{x}}
    {%- endfor %}

include:
    {%- for x in found %}
    - {{x}}
    {%- endfor %}


{%-         endif %}
{%- if not_found %} 
x-role-not-found:
    {%- for x in not_found %}
    - ' not found {{','.join(x)}}'
    {%- endfor %}
{%- endif %}
{%-     endif %}
{%- endif %}
