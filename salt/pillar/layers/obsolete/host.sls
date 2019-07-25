{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {{sls}}: {{grains.host}}

{%- if 'host' in grains and grains.host not in ['', None] %}
{%-     set check = '.'.join(['layers','host',grains.host]) %}
{%-     set success, where = salt['roots.exists'](check,'pillar') %}

_host_layer: {{check}}

_attempted_load:
    {{check}}:

{%-     if success %}

include:
    - {{check}}

{%-     else %}

_not_found:
    host:
        - {{check}}

{%-     endif %}

{%- endif %}
