{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'layers' in grains and grains.layers is mapping and 'lan' in grains.layers %}
    {{sls}}: {{grains.layers.lan|json}}
    {%- else %}
    {{sls}}: 'no lan layer set yet, or not a mapping'
    {%- endif %}

{%- if 'layers' in grains and grains.layers is mapping and 'lan' in grains.layers and grains.layers.lan %}
{%-     set check = '.'.join(['layers','lan',grains.layers.lan]) %}
{%-     set success, where = salt['roots.exists'](check,'pillar') %}

_lan_layer: {{check}}

_attempted_load:
    {{check}}:

{%-     if success %}

include:
    - {{check}}

{%-     else %}

_not_found:
    lan:
        - {{check}}

{%-     endif %}

{%- endif %}
