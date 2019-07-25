{{ salt.loadtracker.load_pillar(sls) }}

{#- # Allow layers to be specified as a list or a comma separated string #}

#
# Example grain values:
#
#layers-sequence:
#    - soe
#    - role
#    - site
#    - lan
#    - host
#    - lan-host
#    - private
#
#layers:
#    soe: demo             # search for layers/soe/demo
#    role: G@roles     # search for layers/role/{role} for each role in grains.roles
#    site: testing         # search for layers/site/testing
#    lan: usb-vm           # search for layers/lan/usb-vm
#    host: G@host      # search for layers/host/{grains.host}
#    lan-host:             # search for layers/lan/{grains.lan}/host/{grains.host} for each lan in grains.lan
#        lan: G@lan
#        host: G@host
#    private: example.private # search for layers/private/example/private
#
#
#
#
{%- set default_sequence = ['soe','role','site','lan','host','lan-host','private'] %}

{%- if True %}
{%- set layers_sequence = grains['layers-sequence'] if 'layers-sequence' in grains else default_sequence %}
{%  else %}
{%- set layers_sequence = ['host'] %}
{%- endif %}

{%- set default_layers = { 'soe': 'demo', 'role': 'G@roles', 'site': 'demo', 'lan': 'demo', 'host': 'G@host' } %}

{%- if True %}
{%- set layers = grains.layers if 'layers' in grains else default_layers %}
{%  else %}
{%- set layers = { 'soe': 'demo', 'host': 'G@host'} %}
{%- endif %}


{%- if 'layers' in grains %}
{#- Show in pillar which layers were specified, for troubleshooting #}
#grain_layers:   {{grains.layers|json}}
{%- else %}
#default_layers: {{layers|json}}
{%- endif %}

{%- set not_configured = [] %}
{%- set badly_configured = [] %}
{%- set values_for = {} %}
{%- if layers %}
{%-     for layer_name in layers_sequence %}
{%-         set accepted = [] %}
{%-         set layer_data = layers[layer_name] if layer_name in layers else '' %}
{%-         if layer_data == '' %}
{%-             do not_configured.append(layer_name) %}
{%-         else %}
{%-             if layer_data is string %}
{%-                 do accepted.append({layer_name : layer_data.split(',') }) %}
{%-             elif layer_data is mapping %}
{%-                 do accepted.append(layer_data) %}
{%-             elif layer_data is iterable %}
{%-                 do accepted.append({layer_name: layer_data}) %}
{%-             else %}
{%-                 do badly_configured.append("Layer "~layer_name ~ " is badly configured - a list or string or mapping was expected") %}
{%-             endif %}
{%-         endif %}
{%-         if accepted %}
{%-             do values_for.update({layer_name: accepted[0]}) %}
{%-         endif %}
{%-     endfor %}
{%- endif %}

{%- set notfound = [] %}

{%- set candidates = [] %}
{%- for layer_name in layers_sequence %}
{%-     set values_for_layer = values_for[layer_name] %}
{%-     if values_for_layer %}
{%-         set builder = [] %}
{%-         for subdir_name, values in values_for_layer.iteritems() %}
{%-             do builder.append(subdir_name) %}
{%-             set sub_items = [] %}
{%-             set wrapper = [values] if (values is string or values is not iterable) else values %}
{%-             for x in wrapper %}
{%-                 if not x.startswith('G@') %}
{%-                     if x %}
{%-                         do sub_items.append(x) %}
{%-                     else %}
{%-                     endif %}
{%-                 else %}
{%-                     set grain_key = x[2:] %}
{%-                     set grain_value = salt['grains.get'](grain_key,[]) %}
{%-                     if grain_value is string or grain_value == 0 or grain_value is not iterable %}
{%-                         if grain_value != '' %}
{%-                             do sub_items.extend(grain_value.split(',') if grain_value is string else [grain_value] if grain_value is not iterable else [] if grain_value is mapping else grain_value) %}
{%-                         else %}
{%-                         endif %}
{%-                     elif grain_value is iterable %}
{%-                         for y in grain_value %}
{%-                             if (y is string and y != '') or y == 0 or y is not iterable %}
{%-                                 do sub_items.append(y) %}
{%-                             elif y is iterable and y is not mapping %}
{%-                                 do sub_items.extend(y) %}
{%-                             else %}
{%-                             endif %}
{%-                         endfor %}
{%-                     else %}
{%-                         do badly_configured.append("Bad grain value for layer " ~ layer_name ~ " and grain key '"~grain_key ~ "'")%}
{%-                     endif %}
{%-                 endif %}
{%-            endfor %}
{%-            do builder.append(sub_items) %}
{%-        endfor %}
{%-        set iterdata = {'rows': ['layers'] } %}
{%-        set depth = builder|length %}
{%-        set discard=[] %}

{%-        for b in builder %}
{%-            set prior_rows = iterdata['rows'] %}
{%-            set new_rows = [] %}
{%-            if b == '' %}
{%-                do discard.append(True) %}
{%-            elif discard %}
{#-                # There is no break or continue in jinja #}
{#-                # but we just do nothing from here on out #}
{%-            elif b is string or b is not iterable %}
{%-                for r in prior_rows %}
{%-                    set check = r ~ '.' ~ b %}
{%-                    if salt['roots.exists'](check,'pillar') %}
{%-                        do new_rows.append(check) %}
{%-                    else %}
{%-                        do notfound.append(check) %}
{%-                    endif %}
{%-                endfor %}
{%-            elif b is iterable and b is not mapping %}
{%-                for r in prior_rows %}
{%-                    for x in b %}
{%-                        set check = r ~ '.' ~ x %}
{%-                        if salt['roots.exists'](check,'pillar') %}
{%-                            do new_rows.append(check) %}
{%-                        else %}
{%-                            do notfound.append(check) %}
{%-                        endif %}
{%-                    endfor %}
{%-                endfor %}
{%-            else %}
{%-            endif %}
{%-            do iterdata.update({'rows': new_rows}) %}
{%-        endfor %}
{%-        if discard %}
{%-            do iterdata.update({'rows':[]}) %}

_layers_invalid: 
     problem: no layers processed due to syntax error or empty value
     badly_configured: {{badly_configured|json}}

{%-        endif %}

{%-        if 'rows' in iterdata and iterdata['rows'] %}
{%-            do candidates.extend(iterdata['rows']) %}
{%-        endif %}
{%-     endif %}
{%- endfor %}

{%- if candidates %}
include: {{candidates|json}}
{%- endif %}

{#- Show in pillar which layers were included, for troubleshooting #}

_layer_includes: {{candidates|json}}

_layer_not_found: {{notfound|json}}
