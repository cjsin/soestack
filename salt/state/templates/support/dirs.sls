{#
# Requires an 'args' with keys :
#    - suffix (optional)- a unique suffix for generating unique state names
#
#    - pillar_location - a pillar key path where we can look for data
#    OR
#    - dirs 
#
#}

{%- set prefix, suffix = salt.uuid.ids(args) %}
{%- set defaults        = args.defaults if 'defaults' in args else {} %}

{%- if 'dirs' in args and args.dirs %}
{%-     set dirs = args.dirs %}
{%- elif 'pillar_location' in args and args.pillar_location %}
{%-     set dirs = salt['pillar.get'](pillar_location,{}) %}
{%- endif %}

{%- if dirs %}
{#-     # need to operate on a sorted list of keys so that parents are created before children #}
{%-     set keys = dirs.keys()|sort %}
{%-     for name in keys %}
{%-         set data = dirs[name] %}
{%-         set spec = {} %}
{%-         do spec.update(data if data else {}) %}
{%-         with args = { 'item_type': 'dir', 'path': name, 'spec': spec, 'defaults': defaults, 'prefix': prefix, 'suffix': suffix } %}
{%             include('templates/support/fsitem.sls') with context %}
{%-         endwith %}
{%-     endfor %}
{%- endif %}
