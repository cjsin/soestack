{#
#
#  Create templates on the filesystem which can then be used
#  to generate files
#
#  The following variables are expected:
#     - suffix
#     - templates OR pillar_location
#
#}

{%- set prefix, suffix = salt.uuids.ids(args) %}
{%- set pillar_location = args.pillar_location if 'pillar_templates' in args and args.pillar_location else '' %}
{%- set templates = args.templates if ('templates' in args and args.templates) else (salt['pillar.get'](pillar_location,{}) if pillar_location else {}) %}

{%- if not templates %}
{{sls}}.statesupport-no-templates-defined-for-{{suffix}}:
    noop.notice:
        - text: |
            {{deployment|json}}

{%- endif %}

{%- if templates %}

{{sls}}.statesupport-template-templates-parent-dir-created-{{suffix}}:
    file.directory:
        - name:     /var/lib/soestack
        - user:     root
        - group:    root 
        - mode:     '0755'

{{sls}}.statesupport-template-templates-dir-created-{{suffix}}:
    file.directory:
        - name:     /var/lib/soestack/templates/
        - user:     root
        - group:    root 
        - mode:     '0700'
        
{%-     for name, contents in templates.iteritems() %}

{{sls}}.statesupport-template-{{name}}-{{suffix}}:
    file.managed:
        - name:     /var/lib/soestack/templates/{{name}}.jinja
        - makedirs: True
        - user:     root
        - group:    root
        - mode:     600
        {%- if contents.startswith('salt://') %}
        - source: {{contents}}
        {%- else %}
        - contents: |
            {{contents|indent(12)}}
        {%- endif %}
{%-     endfor %}
{%- endif %}
