#!stateconf yaml . jinja 

{%- if 'selinux' in pillar %}
{%-     if 'booleans' in pillar.selinux %}
{%-         for bool_name, bool_value in pillar.selinux.iteritems() %}

# TODO 

{%-         endfor %}
{%-     endif %}
{%- endif %}
