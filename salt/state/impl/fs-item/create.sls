{%- set this = _args.this %}
{%- set type = this.type %}
{%- set prefix, suffix  = salt.uuid.ids() %}
{%- set path = this.path %}
{%- if type == 'dir' %}

.fsitem-{{type}}.{{path}}.{{suffix}}:
    file.directory:
        - name:  '{{path}}'
        - user:  '{{this.user}}'
        - group: '{{this.group}}'
        - mode:  '{{this.mode}}'
        - makedirs: {{this.mkdirs}}
{%- elif type == 'file' %}
.fsitem-{{type}}.{{path}}.{{suffix}}:
    file.directory:
        - name:  '{{path}}'
        - user:  '{{this.user}}'
        - group: '{{this.group}}'
        - mode:  '{{this.mode}}'
        - makedirs: {{this.mkdirs}}
        {%- if 'template' in this and this.template not in ['', 'unset' ] %}
        - template: |
            {{this.template|indent(12)}}
        {%- else  %}}
        - contents: |
            {{this.contents|indent(12)}}
        {%- endif %}

{%- elif type == 'link' %}
.fsitem-{{type}}.{{path}}.{{suffix}}:
    file.symlink:
        - name:  '{{path}}'
        - user:  '{{this.user}}'
        - group: '{{this.group}}'
        - mode:  '{{this.mode}}'
        - makedirs: {{this.mkdirs}}
        - target:   '{{this.target}}'

{%- endif %}