{{ salt.loadtracker.load_pillar(sls) }}

# Example grain values:
# layers:
#     soe: demo
#     lan: usb-vm
#     site: testing
#     private: example.private
#
# layers-sequence:
#     - soe=soe/G@layers:soe
#     - role=role/G@roles
#     - site=site/G@layers:site
#     - lan=lan/G@layers:lan
#     - host=host/G@host
#     - lan-host=lan/G@layers:lan/host/G@host
#     - private=private/G@layers:private
#
#

{%- set default_sequence = [
     'soe=soe/G@layers:soe',
     'role=role/G@roles',
     'site=site/G@layers:site',
     'lan=lan/G@layers:lan',
     'host=host/G@host',
     'lan-host=lan/G@layers:lan/host/G@host',
     'private=private/G@layers:private',
]%}

{%- set default_layers = {
        'soe': 'demo', 
        'site': 'demo',
        'lan': 'demo',
        'private': 'example.private'
} %}

{%- set sequence = grains['layers-sequence'] if 'layers-sequence' in grains else default_sequence %}
{%- set layers   = grains['layers']          if 'layers' in grains else default_layers %}
{%- set badly_configured = [] %}
{%- set notfound = [] %}
{%- set candidates = [] %}
{%- for layerspec in sequence %}
{%-     set layer_name, layerpath = layerspec.split('=',1) %}
{%-     set builder = [] %}
{%-     set pathcomponents = layerpath.split('/') %}
{%-     for p in pathcomponents %}
{%-         set sub_items = [] %}
{%-         if not p.startswith('G@') %}
{%-             do sub_items.append(p) %}
{%-         else %}
{%-             set grain_key = p[2:] %}
{%-             set grain_value = salt['grains.get'](grain_key,[]) %}
{%-             if grain_value is string or grain_value == 0 or grain_value is not iterable %}
{%-                 if grain_value != '' %}
{%-                     do sub_items.extend(grain_value.split(',') if grain_value is string else [grain_value] if grain_value is not iterable else [] if grain_value is mapping else grain_value) %}
{%-                 endif %}
{%-             elif grain_value is iterable %}
{%-                 for y in grain_value %}
{%-                     if (y is string and y != '') or y == 0 or y is not iterable %}
{%-                         do sub_items.append(y) %}
{%-                     elif y is iterable and y is not mapping %}
{%-                         do sub_items.extend(y) %}
{%-                     endif %}
{%-                 endfor %}
{%-             else %}
{%-                 do badly_configured.append("Bad grain value for layer " ~ layer_name ~ " and grain key '"~grain_key ~ "'")%}
{%-             endif %}
{%-         endif %}
{%-         if sub_items %}
{%-             do builder.append(sub_items) %}
{%-         endif %}
{%-     endfor %}
{%-     set iterdata = {'rows': ['layers'] } %}
{%-     set depth = builder|length %}
{%-     set discard=[] %}

_layers_builder_for_{{layer_name}}: {{builder|json}}

{%-     for b in builder %}
{%-         set prior_rows = iterdata['rows'] %}
{%-         set new_rows = [] %}
{%-         if b == '' %}
{%-             do discard.append(True) %}
{%-         elif discard %}
{#-             # There is no break or continue in jinja #}
{#-             # but we just do nothing from here on out #}
{%-         elif b is string or b is not iterable %}
{%-             for r in prior_rows %}
{%-                 set check = r ~ '.' ~ b %}
{%-                 if salt['roots.exists'](check,'pillar') %}
{%-                     do new_rows.append(check) %}
{%-                 else %}
{%-                     do notfound.append(check) %}
{%-                 endif %}
{%-             endfor %}
{%-         elif b is iterable and b is not mapping %}
{%-             for r in prior_rows %}
{%-                 for x in b %}
{%-                     set check = r ~ '.' ~ x %}
{%-                     if salt['roots.exists'](check,'pillar') %}
{%-                         do new_rows.append(check) %}
{%-                     else %}
{%-                         do notfound.append(check) %}
{%-                     endif %}
{%-                 endfor %}
{%-             endfor %}
{%-         endif %}
{%-         do iterdata.update({'rows': new_rows}) %}
{%-     endfor %}


{%-     if discard %}
{%-         do iterdata.update({'rows':[]}) %}

_layers_invalid: 
     problem: no layers processed due to syntax error or empty value
     badly_configured: {{badly_configured|json}}

{%-     endif %}

{%-     if 'rows' in iterdata and iterdata['rows'] %}
{%-         do candidates.extend(iterdata['rows']) %}
{%-     endif %}

{#- # end for each layer in the defined sequence #}
{%- endfor %}

{%- if candidates %}
include: {{candidates|json}}
{%- endif %}

{#- Show in pillar which layers were included, for troubleshooting #}

_layer_includes: {{candidates|json}}

_layer_not_found: {{notfound|json}}
