{#
# Requires variables:
#    - suffix
#    - symlinks   OR pillar_location
#}

{%- set suffix          = args.suffix if 'suffix' in args else salt['cmd.exec_code']('python','import uuid; print(str(uuid.uuid4())); ')[:8] %}
{%- set pillar_location = args.pillar_location if 'pillar_location' and args.pillar_location else '' %}
{%- set pillar_data     = salt['pillar.get'](pillar_location,{}) if pillar_location else {} %}
{%- set symlinks        = args.files if ('symlinks' in args and args.symlinks) else (pillar_data.symlinks if 'symlinks' in pillar_data and pillar_data.symlinks else {}) %}

{%- if symlinks %}
{%-    for name, spec in symlinks.iteritems() %}
{%-        if spec %}

{{sls}}.statesupport-symlink-{{name}}-{{suffix}}:
    file.symlink:
        - name:     {{name}}
        - target:   {{spec}}
        - makedirs: True

{%-        endif %}
{%-    endfor %}
{%- endif %}
