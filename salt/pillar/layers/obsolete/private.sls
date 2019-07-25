{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'layers' in grains and grains.layers is mapping and 'private' in grains.layers %}
    {{sls}}: {{grains.layers.private|json}}
    {%- else %}
    {{sls}}: 'no private layer set yet, or not a mapping'
    {%- endif %}

{%- if 'layers' in grains and grains.layers is mapping and 'private' in grains.layers and grains.layers.private %}
{%-     set check = '.'.join(['layers','private',grains.layers.private,'private']) %}
{%-     set success, where = salt['roots.exists'](check,'pillar') %}

_private_layer: {{check}}

_attempted_load:
    {{check}}:

{%-     if success %}

include:
    - {{check}}

{%-     else %}

_not_found:
    private:
        - {{check}}

{%-     endif %}

{%- endif %}
