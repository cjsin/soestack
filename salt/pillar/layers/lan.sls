{%- if 'layers' in grains and grains.layers is mapping and 'lan' in grains.layers and grains.layers.lan %}
{#-    # wtf, it seems slspath is not set at all while processing pillar data #}
{#-    # so it is hard coded here for now, but should raise a bug or feature request with saltstack #}
{%-    set slspath = 'layers' %}
{%-    set prefix = '/' if slspath else '' %}

lan_layer_is: {{grains.layers.lan}}

# attempted_load:
#     {{slspath ~ '/lan/' ~ grains.layers.lan ~ '.sls'}}: 

{%     include(slspath ~ prefix ~ 'lan/' ~ grains.layers.lan ~ '.sls') ignore missing %}

{%- endif %}
