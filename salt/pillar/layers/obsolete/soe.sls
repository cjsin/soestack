{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'layers' in grains and grains.layers is mapping and 'soe' in grains.layers %}
    {{sls}}: {{grains.layers.soe|json}}
    {%- else %}
    {{sls}}: 'no layers soe grain set yet, or not a mapping' 
    {%- endif %}

{%- if 'layers' in grains and grains.layers is mapping and 'soe' in grains.layers and grains.layers.soe %}
{%-     set check = '.'.join(['layers.soe',grains.layers.soe]) %}

{#- Record the site layer, for troubleshooting #}
_soe_layer: {{check}}

{%-     if salt['roots.exists'](check,'pillar') %}

include:
    - {{check}}

{%- else %}

_not_found:
    soe:
        - {{check}}

{%-     endif %}

{%- endif %}
