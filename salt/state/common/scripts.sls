#!stateconf yaml . jinja

#
# Example pillar data:
#
#installed_scripts:
#    local-bin:
#        from:  salt://scripts
#        to:    /usr/local/bin
#        mode:  '0755'
#        common:
#            - yum-refresh
#        workstation-node:
#            - nvidia-setup
#    local-sbin:
#        from:  salt://scripts
#        to:    /usr/local/sbin
#        mode:  '0755'
#        workstation-node:
#            - nvidia-setup
#

{%- if 'installed_scripts' in pillar and pillar.installed_scripts %}
{%-     for groupname, config in pillar.installed_scripts.iteritems() %}
{%-         set from = config.from if 'from' in config else '' %}
{%-         set to   = config.to   if 'to' in config else '' %}
{%-         set mode = config.mode if 'mode' in config else '0755' %}
{%-         for subkey, items in config.iteritems() %}
{%-             if subkey not in [ 'from', 'to' ] %}
{%-                 set matched = [] %}
{%-                 if subkey == 'common' %}
{%-                     do matched.append(subkey) %}
{%-                 else %}
{%-                     set subkey_parts = subkey.split(',') %}
{%-                     for part in subkey_parts %}
{%-                         if part in grains.roles %}
{%-                             do matched.append(part) %}
{%-                         endif %}
{%-                     endfor %}
{%-                 endif %}
{%-                 if matched %}
{%-                     for item in items %}

{{sls}}.{{groupname}}-{{item}}:
    file.managed:
        - name:    '{{to}}/{{item}}'
        - source:  '{{from}}/{{item}}'
        - user:    root
        - group:   root
        - mode:    '{{mode}}'
        - template: jinja

{%-                     endfor %}
{%-                 endif %}
{%-             endif %}
{%-         endfor %}
{%-     endfor %}
{%- endif %}
