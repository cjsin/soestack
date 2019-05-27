_loaded_layers:
    {%- if 'layers' in grains and grains.layers is mapping and 'site' in grains.layers %}
    {{sls}}: {{grains.layers.site|json}}
    {%- else %}
    {{sls}}: 'no layers site grain set yet, or not a mapping' 
    {%- endif %}

{%- if 'layers' in grains and grains.layers is mapping and 'site' in grains.layers and grains.layers.site %}
{#-    # wtf, it seems slspath is not set at all while processing pillar data #}
{#-    # so it is hard coded here for now, but should raise a bug or feature request with saltstack #}
{%-    set slspath = 'layers' %}
{%-    set prefix = '/' if slspath else '' %}

site_layer_is: {{grains.layers.site}}

# attempted_load:
#     {{slspath ~ '/site/' ~ grains.layers.site ~ '.sls'}}: 

{%     include(slspath ~ prefix ~ 'site/' ~ grains.layers.site ~ '.sls') ignore missing %}

{%- endif %}
