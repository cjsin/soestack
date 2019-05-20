#
#  This template expects the variable 'args' containing the following keys:
#    - dotd_path      <the directory in which to create files>
#    - pillar_key     <the pillar key in which to look for items>
#    - contentdir     <the path in which to look for template files or static files>
#                     this must be specified if a static file or template is defined
#    - extension      <the file extension to add to the item name>
#    - mode           <the file permissions>
#    - user           <the file owner>
#    - group          <the file group>
#
#  It will process pillar data in the following style:
#
#   <pillar_key>:
#       <item-name>:
#           enabled:   <True|False>  (if enabled, one of 'contents','file' or 'template' is expected also)
#           contents:  <text content>
#           file:      <static file name>
#           template:  <template file name> (searched for within 'contentdir')
#           config:    <freeform data structure available to the template as 'config'> 
#           config_pillar:   <path to a pillar key which will be available to the template as 'config'> 
#
#  example usage:
#
#  salt state usage example:
#
#      set args = { 'dotd_path': '/etc/profile.d', 'pillar_key': 'bash:profile', 'extension': 'sh' : 'contentdir': slspath }
#      include('template/dotd_folder.sls) with context 
#
#  salt pillar data example:
#
#      bash:
#          profile:
#              example:
#                  enabled:        True
#                  template:       example.sh.jinja
#                  config_pillar:  example:config
#      example:
#          config:
#              a: 1
#              b: 2
#

{%- set arg_defaults = {
    'user':      'root',
    'group':     'root',
    'mode':      '0644',
    'extension': ''
} %}

{%- set params = {} %}
{%- do params.update(arg_defaults) %}
{%- do params.update(args) %}

{%- set dot_ext = '.' ~ params.extension if params.extension else '' %}

{%- set pillar_data = salt['pillar.get'](params.pillar_key,{}) %}

{%- for name, item in pillar_data.iteritems() %}

.dotd-file-{{params.dotd_path}}-{{name}}:
    file.{{'managed' if item.enabled else 'absent'}}:
        - name:     '{{params.dotd_path}}/{{name}}{{dot_ext}}'
        - mode:     '{{params.mode}}'
        - user:     '{{params.user}}'
        - group:    '{{params.group}}'
        {%- if 'contents' in item %}
        - contents: |
            {{item.contents|indent(12)}}
        {%- elif 'key' in item %}
        - contents_pillar: {{ item.key }}
        {%- elif 'file' in item %}
        - source:   salt://{{params.contentdir}}/{{item.file}}
        {%- elif 'template' in item %}
        - source:   salt://{{params.contentdir}}/{{item.template}}
        - template: jinja
        - context:
            {%- if 'config' in item %}
            config: {{item.config|json}}
            {%- elif 'config_pillar' in item %}
            config: {{salt['pillar.get'](item.config_pillar,{})|json}}
            {%- endif %}
        {%- endif %}

{%- endfor %}
