{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {%- if 'layers' in grains and grains.layers is mapping and 'private' in grains.layers %}
    {{sls}}: {{grains.layers.private|json}}
    {%- else %}
    {{sls}}: 'no private layer set yet, or not a mapping'
    {%- endif %}

{%- if 'layers' in grains and grains.layers is mapping and 'private' in grains.layers and grains.layers.private %}
{#-    # wtf, it seems slspath is not set at all while processing pillar data #}
{#-    # so it is hard coded here for now, but should raise a bug or feature request with saltstack #}
{%-    set privlayer = grains.layers.private %}
{%-    set attempted_load = ['layers','private', privlayer, 'private.sls']|join('/') %}

private_layer_is: {{privlayer}}

attempted_load:
    {{attempted_load}}: 

{%     include(attempted_load) ignore missing %}
{%- endif %}
