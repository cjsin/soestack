# This file is obsolete - the template support/filesystem is used instead
#
# Requires variables:
#    - nugget
#    - nugget_name
#    - suffix
#
{%- if 'files' in nugget %}
{%-    set nugget_location = 'nuggets:'~nugget_name %}
{%-    for name, spec in nugget.files.iteritems() %}

{%-        set contents_specified = spec.contents if 'contents' in spec else None %}
{%-        set contents_pillar_specified = spec.contents_pillar if ( not (contents_specified is defined) and 'contents_pillar' in spec and spec.contents_pillar) else '' %}
{%-        set contents_pillar = (nugget_location ~ contents_pillar_specified if contents_pillar_specified[0] == ':' else contents_pillar_specified) if contents_pillar_specified else '' %}

{%-        set config_specified = spec.config if 'config' in spec else None %}
{%-        set config_pillar_specified = spec.config_pillar if ('config_pillar' in spec and spec.config_pillar) else '' %}
{%-        set config_pillar = (nugget_location ~ config_pillar_specified if config_pillar_specified[0] == ':' else spec.config_pillar_specified) if config_pillar_specified else '' %}

{%-        set config = config_specified if (config_specified != None) else (salt['pillar.get'](config_pillar,{}) if config_pillar else {}) %}

nugget-{{nugget_name}}-file-{{name}}-{{suffix}}:
    file.managed:
        - name:     {{name}}
        - user:     {{spec.user if 'user' in spec else 'root'}}
        - group:    {{spec.group if 'group' in spec else 'root'}}
        - mode:     {{spec.mode if 'mode' in spec else '0644'}}
        - makedirs: True
        {%- if 'template' in spec %}
        - template: jinja
        - source:   /var/lib/soestack/nuggets/templates/{{spec.template}}.jinja
        - context: {{config|json}}
        {%- else %}
        {%-     if contents is defined %}
        - contents: |
            {{contents|indent(12)}}
        {%-     elif contents_pillar %}
        - contents_pillar: {{contents_pillar}}
        {%-     endif %}
        {%- endif %}

{%-    endfor %}
{%- endif %}
