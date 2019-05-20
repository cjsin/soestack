# This state is obsolete - support/filesystem is used instead.
#
# Requires variables:
#    - nugget
#    - nugget_name
#    - suffix
#
{%- if 'symlinks' in nugget %}
{%-    set nugget_location = 'nuggets:'~nugget_name %}
{%-    for name, spec in nugget.symlinks.iteritems() %}
{%-        if spec %}

nugget-{{nugget_name}}-symlink-{{name}}-{{suffix}}:
    file.symlink:
        - name:     {{name}}
        - target:   {{spec}}
        - makedirs: True

{%-        endif %}
{%-    endfor %}
{%- endif %}
