_loaded:
    {{sls}}:

{#- # Allow layers to be specified as a list or a comma separated string #}

#
# Example grain values:
#
# grains:
#     layers: layer1,layer2,host
#
# grains:
#     layers;
#         - layer1
#         - layer2
#         - host
#
# Or, use standard soe,site,lan layers, which will be followed by the host layer
# 
# grains:
#     layers:
#         soe:  example_soe
#         site: example_site
#         lan:  example_lan
#

{%- if 'layers' in grains %}

grain_layers: {{grains.layers|json}}

{%- endif %}

{%- if 'layers' in grains and grains.layers %}

{%-     set selected_layers = [] %}

{%-     if  grains.layers is iterable %}
{%-         if grains.layers is not mapping %}
{%-             set layers = grains.layers.split(',') if grains.layers is string else grains.layers %}
{%-             if layers %}
{%-                 do selected_layers.extend(layers) %}
{%-             endif %}
{%-         elif grains.layers is mapping %}
{#-             # If the layer grain is a mapping, it is expected to be a dict specifying #}
{#-             #   names for the following keys: soe,role,role,site,lan,host which will be processed in that order #}
{%-             do selected_layers.extend(['soe', 'role', 'site', 'lan', 'host']) %}
{%-         endif %}
{%-     endif %}

selected_layers: {{selected_layers|json}}

{%-     set attempted_loads = [] %}

{%-     if selected_layers %}

{#-         # This was the first implementation, but including multiple files #} 
{#-         # with a jinja include leads to conflicting ID errors #}
{%-         if False %}
{%-             set prefix = '/' if slspath else '' %}
{%-             for layer in selected_layers %}
{%-                 set layer_filename = slspath ~ prefix ~ 'layers/' ~ layer ~ '.sls' %}
{%-                 do attempted_loads.append(layer_filename) %}
{%                  include(layer_filename) ignore missing %}
{%-             endfor %}
{%-         else %}

{#-             # Hopefully using yaml include will work better #}

include:
    {%-         for layer in selected_layers %}
    {%-            do attempted_loads.append(layer) %}
    - layers.{{layer}}
    {%-         endfor %}
    - layers.lan-host

layer-include:
    {%-         for layer in selected_layers %}
    {%-            do attempted_loads.append(layer) %}
    - layers.{{layer}}
    {%-         endfor %}
    - layers.lan-host

{%-         endif %}
{%-     endif %}

attempted_layers: {{attempted_loads|json}}

{%- endif %}
