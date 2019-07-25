{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'layers' in grains and grains.layers is mapping and 'site' in grains.layers %}
    {{sls}}: {{grains.layers.site|json}}
    {%- else %}
    {{sls}}: 'no layers site grain set yet, or not a mapping' 
    {%- endif %}

{%- if 'layers' in grains and grains.layers is mapping and 'site' in grains.layers and grains.layers.site %}
{%-     set check = '.'.join(['layers.site',grains.layers.site]) %}

{#- Record the site layer, for troubleshooting #}
_site_layer: {{check}}

{%-     if salt['roots.exists'](check,'pillar') %}

include:
    - {{check}}

{%-     else %}

_not_found:
    site:
        - {{check}}

{%-     endif %}

{%- endif %}
