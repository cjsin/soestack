#!stateconf yaml . jinja


{%- set cfgfile = '/usr/lib/python2.7/site-packages/terminatorlib/config.py' %}

{%- if salt['file.file_exists'](cfgfile) %}

{{sls}}.patch-terminator-defaults:
    cmd.run:
        - name: |
            sed -i '/scrollback_infinite/ s/False/True/' '{{cfgfile}}'
        - onlyif: egrep 'scrollback_infinite.*False' '{{cfgfile}}'


{%- endif %}
