# Requires variables:
#    - suffix (optional) - a unique tag for keeping state names from conflicting
#    - nugget
#    - nugget_name

#    - pillar_location - a pillar key containing such things as 'files','contents','templates','config'
#        - this will be used when a file specifies a ':' prefixed pillar location when specifying a config key
#        - it will also be used to look up 'files' if no files were specified
#    - files_location
#}

{%- set prefix, suffix = salt.uuids.ids(args) %}
{%- set pillar_location = args.pillar_location if 'pillar_location' and args.pillar_location else '' %}
{%- set pillar_data     = salt['pillar.get'](pillar_location,{}) if pillar_location else {} %}
{%- set symlinks        = args.symlinks if ('symlinks' in args and args.symlinks) else (pillar_data.files if 'symlinks' in pillar_data and pillar_data.symlinks else {}) %}
{%- set defaults        = args.defaults if 'defaults' in args else {} %}
{%- if symlinks %}
{%-    for name, spec in symlinks.iteritems() %}
{%-        with args = { 'item_type': 'symlink', 'path': name, 'spec': spec, 'defaults': defaults, 'pillar_location': pillar_location, 'prefix': prefix, 'suffix': suffix } %}
{%             include('templates/support/fsitem.sls') with context %}
{%-        endwith %}
{%-    endfor %}
{%- endif %}
