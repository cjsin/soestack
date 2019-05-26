{%- import 'lib/noop.sls' as noop %}

{%- set diagnostics    = False %}

{%- set path           = args.path %}
{%- set fallbacks      = {  
                            'file_mode': '0644', 
                            'dir_mode': '0755', 
                            'selinux': '', 
                            'makedirs': False, 
                            'target': '', 
                            'contents': None, 
                            'contents_pillar': None,
                            'config': None,  
                            'config_pillar': None,
                         } %}
{%- set defaults       = args.defaults if 'defaults' in args and args.defaults else {} %}
{%- set prefix, suffix = salt.uuid.ids(args) %}
{%- set item_type      = args.item_type %}
{%- set args_spec      = args.spec %}
{%- set spec           = {} %}
{%- do  spec.update(fallbacks) %}
{%- do  spec.update(defaults) %}
{%- do  spec.update(args_spec) %}

{%- if diagnostics %}
{{noop.pprint('fsitem fallbacks', fallbacks)}}
{{noop.pprint('fsitem defaults', defaults)}}
{{noop.pprint('fsitem args_spec', args_spec)}}
{{noop.pprint('fsitem spec', spec)}}
{%- endif %}

{#- # the salt file state module does not set file ownership based on numeric IDs so we have #}
{#- # to check for this and do it manually #}
{%- set user           = spec.user  if 'user'  in spec and spec.user  is not number else '' %}
{%- set group          = spec.group if 'group' in spec and spec.group is not number else '' %}
{%- set uid            = spec.user  if 'user'  in spec and spec.user  is number else '' %}
{%- set gid            = spec.group if 'group' in spec and spec.group is number else '' %}
{%- set makedirs       = spec.makedirs if 'makedirs' in spec and spec.makedirs != None else True %}
{%- set mode_key       = item_type ~ '_mode' %}
{%- set specific_mode  = spec[mode_key] if mode_key in spec and spec[mode_key] != '' and spec[mode_key] != None else '' %}
{%- set generic_mode   = spec.mode if 'mode' in spec and spec.mode != '' and spec.mode != None else '' %}
{%- set default_mode   = fallbacks[mode_key] %}
{%- set mode           = specific_mode if specific_mode != '' else (generic_mode if generic_mode != '' else default_mode) %}
{%- set selinux        = spec.selinux if 'selinux' in spec and spec.selinux else '' %}
{%- set target         = spec.target  if 'target' in spec and spec.target else '' %}

{%- if item_type in [ 'file', 'dir', 'symlink' ] %}

{%-     if item_type == 'file' %}

{%-         set contents_specified        = spec.contents        if 'contents' in spec else None %}
{%-         set contents_pillar_specified = spec.contents_pillar if ( not (contents_specified is defined) and 'contents_pillar' in spec and spec.contents_pillar) else '' %}
{%-         set contents_pillar           = (pillar_location ~ contents_pillar_specified if contents_pillar_specified[0] == ':' else contents_pillar_specified) if contents_pillar_specified else '' %}

{%-         set config_specified          = spec.config        if 'config' in spec else None %}
{%-         set config_pillar_specified   = spec.config_pillar if ('config_pillar' in spec and spec.config_pillar) else '' %}
{%-         set config_pillar             = (pillar_location ~ config_pillar_specified if config_pillar_specified[0] == ':' else spec.config_pillar_specified) if config_pillar_specified else '' %}

{%-         set config = config_specified if (config_specified != None) else (salt['pillar.get'](config_pillar,{}) if config_pillar else {}) %}
{%-     endif %}

{%-     set state_func = 'managed' if item_type == 'file' else ('directory' if item_type == 'dir' else 'symlink' if item_type == 'symlink'  else 'unknown') %}

{%- if diagnostics %}
{{sls}}.NOTICE-debug-{{prefix}}fs-{{item_type}}-{{path}}{{suffix}}-info:
    noop.notice:
        - name: |
            spec:
                {{spec|json|indent(16)}}
            args:
                {{args|json|indent(16)}}
            item_type: 
                {{item_type}}
            {%- if item_type == 'file' %}
            contents_specified: 
                {{(contents_specified or '')|yaml|indent(16)}}
            contents_pillar_specified: 
                {{(contents_pillar_specified or '')|yaml|indent(16) }}
            contents_pillar: 
                {{(contents_pillar or '')|yaml|indent(16) }}
            config_specified: 
                {{(config_specified or '')|yaml|indent(16)}}
            config_pillar_specified: 
                {{(config_pillar_specified or '')|yaml|indent(16) }}
            config_pillar: 
                {{(config_pillar or '')|yaml|indent(16) }}
            config: 
                {{config|yaml|indent(16) }}
            {%- endif %}
{%- endif %}

{%-     if state_func %}

{%- if diagnostics %}
{{sls}}.NOTICE-debug-{{prefix}}fs-{{item_type}}-{{path}}{{suffix}}:
    noop.notice:
        - text: |
            file.{{state_func}}:
                - name:     {{path}}
                {%- if item_type == 'symlink' and target %}
                - target:   '{{target}}'
                {%- endif %}
                {%- if user != '' %}
                - user:     {{user}}
                {%- endif %}
                {%- if group != '' %}
                - group:    {{group}}
                {%- endif %}
                {%- if mode != '' and mode != None %}
                - mode:     {{mode}}
                {%- endif %}
                {%- if makedirs != '' %}
                - makedirs: {{makedirs}}
                {%- endif %}

                {#- # File type only #}
                {%- if item_type == 'file' %}
                {%-     if 'template' in spec %}
                - template: jinja
                - source:   /var/lib/soestack/templates/{{spec.template}}.jinja
                - context: 
                    config: {{config|json}}
                {%-     elif 'source' in spec %}
                - source:  {{spec.source}}
                {%-     elif contents_specified is defined and contents_specified is not none %}
                - contents: |
                    {{contents_specified|indent(20)}}
                {%-     elif contents_pillar %}
                - contents_pillar: {{contents_pillar}}
                {%-     else %}
                {#- # If no contents were specified, replace=False is specified so at least #}
                {#- # the user,group,permissions will be set, if the file exists #}
                - replace:  False
                {%-     endif %}
                {%- endif %}
{%- endif %} 


{{sls}}.{{prefix}}fs-{{item_type}}-{{path}}{{suffix}}:
    file.{{state_func}}:
        - name:     {{path}}
        {%- if item_type == 'symlink' and target %}
        - target:   '{{target}}'
        {%- endif %}
        {%- if user != '' %}
        - user:     {{user}}
        {%- endif %}
        {%- if group != '' %}
        - group:    {{group}}
        {%- endif %}
        {%- if mode != '' and mode != None %}
        - mode:     {{mode}}
        {%- endif %}
        {%- if makedirs != '' %}
        - makedirs: {{makedirs}}
        {%- endif %}

        {#- # File type only #}
        {%- if item_type == 'file' %}
        {%-     if 'template' in spec %}
        - template: jinja
        - source:   /var/lib/soestack/templates/{{spec.template}}.jinja
        - context: 
            config: {{config|json}}
        {%-     elif 'source' in spec %}
        - source:  {{spec.source}}
        {%-     elif contents_specified is defined and contents_specified is not none %}
        - contents: |
            {{contents_specified|indent(12)}}
        {%-     elif contents_pillar %}
        - contents_pillar: {{contents_pillar}}
        {%-     else %}
        {#- # If no contents were specified, replace=False is specified so at least #}
        {#- # the user,group,permissions will be set, if the file exists #}
        - replace:  False
        {%-     endif %}
        {%- endif %}

{%-     endif %}

{%-     if gid %}

{{sls}}.{{prefix}}fs-file-{{path}}-gid{{suffix}}:
    cmd.run:
        - name:   chgrp {{gid}} '{{path}}'
        - unless: stat -c %g '{{path}}' | egrep '^{{gid}}$'

{%-     endif %}

{%-     if uid %}

{{sls}}.{{prefix}}fs-{{item_type}}-{{path}}-uid{{suffix}}:
    cmd.run:
        - name:   chown {{uid}} '{{path}}'
        - unless: stat -c %u '{{path}}' | egrep '^{{uid}}$'

{%-     endif %}

{%-     if selinux %}

{{sls}}.{{prefix}}fs-{{item_type}}-{{path}}-selinux{{suffix}}:
    cmd.run:
        - name:   chcon -t '{{selinux}}' '{{path}}'
        - unless: stat -c %C '{{path}}' | grep ':{{selinux}}:'

{%-     endif %}

{%- endif %}
