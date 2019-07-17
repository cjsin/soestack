#!stateconf yaml . jinja

{%- set diagnostics = 'diagnostics' in pillar and sls in pillar.diagnostics %}
{%- if 'filesystem' in pillar %}
{%-     set default_file_mode = '0644' %}
{%-     set default_dir_mode = '0755' %}

{%-     set filesystem = pillar.filesystem %}
{%-     set filesystem_defaults = filesystem.defaults if 'defaults' in filesystem else {'user':'root', 'group':'root','mode':default_file_mode, 'mkdirs': False } %}

{%-     if 'dirs' in filesystem %}
{%-         set base_defaults = {} %}
{%-         do base_defaults.update(filesystem_defaults) %}
{#-         if the mode was applied from the default and not overridden, then make sure it has executable bit set for dirs #}
{%-         if base_defaults.mode == default_file_mode %}
{%-             do base_defaults.update({'mode': default_dir_mode}) %}
{%-         endif %}

{%-         set dirs = filesystem.dirs %}
{%-         set dirs_defaults = dirs.defaults if 'defaults' in dirs else {} %}
{%-         do base_defaults.update(dirs_defaults) %}

{%-         if diagnostics %}
{{sls}}.filesystem-defaults:
    noop.notice:
        - text: |
            {{base_defaults|json}}
{%-         endif %}

{%-         for grouping in ['by-role','by-host'] %}
{%-             if grouping in dirs %}
{%-                 for key, items in dirs[grouping].iteritems() %}
{%-                     set accepted = [] %}
{%-                     if grouping == 'by-role' %}
{%-                         set these_roles = key.split(",") %}
{%-                         for role in grains.roles %}
{%-                             if role in these_roles %}
{%-                                 do accepted.append('role:'~role) %}
{%-                             elif diagnostics %}
{{sls}}.role-{{role}}-did-not-match-{{key}}:
    noop.notice
{%-                             endif %}
{%-                         endfor %}
{%-                     elif grouping == 'by-host' %}
{%-                         set these_hosts = key.split(",") %}
{%-                         for regex in these_hosts %}
{%-                             if grains.host | regex_match(item) %}
{%-                                 do accepted.append('host:'~regex) %}
{%-                             elif diagnostics %}
{{sls}}.host-{{rexex}}-did-not-match-{{grains.host}}:
    noop.notice
{%-                             endif %}
{%-                         endfor %}
{%-                     elif diagnostics %}
{{sls}}.unrecognised-grouping-{{grouping}}:
    noop.notice
{%-                     endif %}
{%-                     if accepted|length > 0 %}
{%-                         for item_name, overrides in items.iteritems() %}
{%-                             set props = {} %}
{%-                             do props.update(base_defaults) %}
{%-                             do props.update(overrides) %}


#                /export/home:
#                    description: Export home directories for clients
#                    user: root
#                    group: root
#                    mode: '0755'
#                    mkdirs: True
#                    export:
#                        1-home:
#                            - '*':       rw,async,root_squash
#                    mount:
#                        path: /home
#                        opts:
#                            - bind

{{sls}}.filesystem-dirs-{{grouping}}-{{key}}-{{item_name}}:
    file.directory:
        - name:     '{{item_name}}'
        - user:     '{{props.user}}'
        - group:    '{{props.group}}'
        - mode:     '{{props.mode}}'
        {%- if props.mkdirs %}
        - makedirs: True
        {%- endif %}

{%-                             if 'export' in props and props.export is mapping and props.export %}
{%-                                 set export_name=props['export'].keys()[0] %}
{%-                                 set export_data=props['export'][export_name] %}
{%-                                 if export_data and export_data is iterable and export_data %}
{%-                                     set clients = [export_data] if export_data is mapping else export_data %}


{{sls}}.exports-dirs-{{grouping}}-{{key}}-{{item_name}}:
    nfs_export.{{'absent' if props.export == False else 'present'}}:
        - name:  {{item_name}}
        - clients:
        {%- for client in clients %}
        {%-     for hosts, opts in client.iteritems() %}
            - hosts: '{{hosts}}'
              options:
              {%-   for opt in (opts.split(',') if opts is string else opts) %}
                  - '{{opt}}'
              {%-   endfor %}
        {%-     endfor %}
        {%- endfor %}


{%- else %}

{{sls}}.exports-dirs-{{grouping}}-{{key}}-{{item_name}}:
    noop.notice:
        - text: |
            apparently, there is no 'export' in {{props|json}}

{%-                                 endif %}
{%-                             endif %}

{%-                             if 'bind' in props and props.bind != False %}
{%-                                 set ro = 'ro' if ('readonly' in props and props.readonly) or ('readwrite' in props and not props.readwrite) else '' %}
{%-                                 set rw = 'rw' if ('readwrite' in props and props.readwrite) or ('readonly' in props and not props.readonly) else '' %}
{%-                                 set rorw = '' if (not ro and not rw) else ',' ~ ro ~ rw %}
{%-                                 if 'dev' in props.bind %}
{{sls}}.add-bind-mount-{{grouping}}-{{key}}-{{item_name}}:
    mount.mounted:
        - name:    {{item_name}}
        - device:  {{props.bind.dev}}
        - fstype:  none
        - opts:
            - bind
            {%- if rorw %}
            - {{rorw}}
            {%- endif %}
            {%- if 'opts' in props and opts.props %}
            {%-     for opt in opts.props %}
            {%-         for item in opts.split(',') %}
            - {{item}}
            {%-         endfor %}
            {%-     endfor %}
            {%- endif %}
        - persist: True
        # extra_mount_invisible_options
        # extra_mount_ignore_fs_keys
        # hidden_opts
{%-                                 endif %}
{%-                             endif %}
{%-                         endfor %}

{%-                     elif diagnostics %}

{{sls}}.no-accepted-paths:
    noop.notice

{%-                     endif %}
{%-                 endfor %}
{%-             endif %}
{%-         endfor %}

{%-     elif diagnostics %}

{{sls}}.no-filesystem-dirs-data:
    noop.notice

{%-     endif %}

{%- elif diagnostics %}

{{sls}}.no-filesystem-data:
    noop.notice

{%- endif %}
