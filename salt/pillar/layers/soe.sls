{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'layers' in grains and grains.layers is mapping and 'soe' in grains.layers %}
    {{sls}}: {{grains.layers.soe|json}}
    {%- else %}
    {{sls}}: 'no layers soe grain set yet, or not a mapping' 
    {%- endif %}

{%- if 'layers' in grains and grains.layers is mapping and 'soe' in grains.layers and grains.layers.soe %}
{#-    # wtf, it seems slspath is not set at all while processing pillar data #}
{#-    # so it is hard coded here for now, but should raise a bug or feature request with saltstack #}
{%-    set slspath = 'layers' %}
{%-    set prefix = '/' if slspath else '' %}

soe_layer_is: |
    {{grains.layers.soe ~', file:' ~ slspath ~ prefix ~ 'soe/' ~ grains.layers.soe ~ '.sls'}}

{%     include(slspath ~ prefix ~ 'soe/' ~ grains.layers.soe ~ '.sls') ignore missing %}

{%- endif %}
