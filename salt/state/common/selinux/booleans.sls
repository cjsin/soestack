#!stateconf yaml . jinja 

{%- if 'selinux' in pillar %}
{%-     if 'booleans' in pillar.selinux %}
{%-         for bool_name, bool_value in pillar.selinux.booleans.iteritems() %}

.{{bool_name}}:
    selinux.boolean:
        - name:    '{{bool_name}}'
        - value:   {{bool_value}}
        - persist: True

{%-         endfor %}
{%-     endif %}
{%- endif %}
