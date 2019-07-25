{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'lan' in grains.layers %}
    {{sls}}: {{[grains.layers.lan, grains.host]|json}}
    {%- else %}
    {{sls}}: {{['no lan layer set', grains.host]|json}}
    {%- endif %}

{%- if 'layers' in grains and grains.layers is mapping and 'lan' in grains.layers and grains.layers.lan %}
{%-     set check = '.'.join(['layers','lan',grains.layers.lan,'host',grains.host]) %}
{%-     set success, where = salt['roots.exists'](check,'pillar') %}

_lan-host_layer: {{check}}

_attempted_load:
    {{check}}:

{%-     if success %}

include:
    - {{check}}

{%-     else %}

_not_found:
    lan-host:
        - {{check}}

{%-     endif %}

{%- endif %}
