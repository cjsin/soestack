{#- This file requires the ext/module 'roots' #}
{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'roles' in grains %}
    {{sls}}: {{grains.roles|json}}
    {%- else %}
    {{sls}}: 'no roles grain set yet'
    {%- endif %}

{%- set found = [] %}
{%- set not_found = [] %}
{%- set roles = grains.roles if 'roles' in grains and grains.roles else  ( grains.role if 'role' in grains and grains.role else []) %}

{%- if roles %}
{%-     for r in roles %}
{%-         set check = '.'.join(['layers','role',r]) %}
{%-         set success, where = salt['roots.exists'](check,'pillar') %}
{%-         if success %}
{%-             do found.append(check) %}
{%-         else %}
{%-             do not_found.append(check) %}
{%-         endif %}
{%-     endfor %}

{%-     if found %}

include: {{found|json}}

x-include: {{found|json}}

{%-     endif %}

{%-     if not_found %} 

_not_found: 
    role: {{not_found|json}}

{%-     endif %}

{%- endif %}
