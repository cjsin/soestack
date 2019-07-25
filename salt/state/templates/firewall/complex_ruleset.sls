{%- set ruleset_name = args.group_name %}
{%- set ruleset = args.group %}
{%- set prefix = args.prefix %}
{%- set suffix = args.suffix %}

{%- for action_name, data in ruleset.iteritems() %}
{%-   with args = { 'ruleset_name': ruleset_name, 'action_name': action_name, 'data': data, 'prefix': prefix, 'suffix': suffix } %}
{%        include('templates/firewall/complex_action.sls') with context %}
{%-   endwith %}
{%- endfor %}
