{%- set name = args.name %}
{%- set prefix, suffix  = salt.uuid.ids(args) %}

{%- set dstip0 = args.ip if 'ip' in args else '' %}
{%- set srcip0 = args.from if 'from' in args else '' %}
{%- set action_group = args.group %}
{%- set dstip = action_group.ip if 'ip' in action_group else dstip0 %}
{%- set srcip = action_group.from if 'from' in action_group else srcip0 %}
{%- for action in [ 'accept', 'reject', 'drop', 'return' ] %}
{%-     if action in action_group %}
{%-         for proto, portmapping in action_group[action].iteritems() %}
{%-             for portname, portrange in portmapping.iteritems() %}
{%-                 with args = { 'name': name ~ '-' ~ portname, 'proto': proto, 'action': action, 'dport': portrange, 'ip': dstip, 'from': srcip } %}
{%                      include('templates/firewall/basic_action.sls') with context %}
{%-                 endwith %}
{%-             endfor %}
{%-         endfor %}
{%-     endif %}
{%- endfor %}
