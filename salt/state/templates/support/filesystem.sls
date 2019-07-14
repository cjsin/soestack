{#- this template uses the following vars: #}
{#-    a mapping with the following keys #}
{#-        - suffix (optional) - for generating unique keys  #}
{#-        - pillar_location   - a pillar key containing 'files','dirs','symlinks','templates' #}
{%- set prefix, suffix = salt.uuids.ids(args) %}

{%- set pillar_location = args.pillar_location if 'pillar_location' and args.pillar_location else '' %}
{%- set pillar_data     = salt['pillar.get'](pillar_location,{}) if pillar_location else {} %}
{%- set parent          = args.parent if ('parent' in args and args.parent) else pillar_data %}
{%- set overrides       = args.defaults if 'defaults' in args else {} %}
{%- set parent_defaults = parent.defaults if 'defaults' in parent else {} %}

{%- set defaults = {} %}
{%- do  defaults.update(parent_defaults) %}
{%- do  defaults.update(overrides) %}

{%- for objtype in [ 'dirs', 'symlinks', 'templates', 'files' ] %}
{%-     if objtype in parent and parent[objtype] %}
{%-         set args = { objtype : parent[objtype], 'pillar_location': pillar_location, 'defaults': defaults } %}
{%          include('templates/support/' ~ objtype ~ '.sls') with context %}
{%-     endif %}
{%- endfor %}

