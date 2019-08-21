{%- set ruleset_name = args.name %}
{%- set ruleset = args.group %}
{%- set prefix = args.prefix %}
{%- set suffix = args.suffix %}

{%- set dstip0 = args.ip if 'ip' in args else '' %}
{%- set srcip0 = args.from if 'from' in args else '' %}
{%- set dstip = ruleset.ip if 'ip' in ruleset else dstip0 %}
{%- set srcip = ruleset.from if 'from' in ruleset else srcip0 %}

{%- for action in [ 'accept', 'reject', 'drop', 'return' ] %}
{%-     if action in ruleset %}
{%-         for proto, portmapping in ruleset[action].iteritems() %}
{%-             for portname, portrange in portmapping.iteritems() %}
{%-                 with args = { 'name': ruleset_name ~ '-' ~ portname, 'proto': proto, 'action': action, 'dport': portrange, 'ip': dstip, 'from': srcip } %}
{%                      include('templates/firewall/basic_action.sls') with context %}
{%-                 endwith %}
{%-             endfor %}
{%-         endfor %}
{%-     endif %}
{%- endfor %}
