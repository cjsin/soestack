{#
#  Create templates on the filesystem which can then be used
#  to generate files
#
#  The following variables are expected:
#     - nugget_name
#     - nugget
#     - suffix
#
#}

{%- if 'templates' in nugget %}
{%-    for name, contents in nugget.templates.iteritems() %}

nugget-{{nugget_name}}-template-{{name}}:
    file.managed:
        - name:     /var/lib/soestack/nuggets/templates/{{name}}.jinja
        - makedirs: True
        - user:     root
        - group:    root
        - mode:     600
        - contents: |
            {{contents|indent(12)}}

{%-    endfor %}
{%- endif %}
