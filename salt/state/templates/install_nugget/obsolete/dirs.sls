{# This file is obsolete - the template support/filesystem is used instead
#
# Requires variables:
#    - nugget
#    - nugget_name
#    - suffix
#}

{%- if 'dirs' in nugget %}
{%-    set nugget_location = 'nuggets:'~nugget_name %}
{%-    for name, data in nugget.dirs.iteritems() %}
{%-        set spec = {'user':'root','group':'root','mode':'0700'} %}
{%-        do spec.update(data if data else {}) %}

nugget-{{nugget_name}}-dir-{{name}}-{{suffix}}:
    file.directory:
        - name:     {{name}}
        - user:     {{spec.user if 'user' in spec else 'root'}}
        - group:    {{spec.group if 'group' in spec else 'root'}}
        - mode:     {{spec.mode if 'mode' in spec else '0644'}}
        - makedirs: True

{%-    endfor %}
{%- endif %}
