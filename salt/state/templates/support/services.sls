{#
# This template requires already defined:
#    - args, containing 'parent'
#}
{%- set prefix, suffix  = salt.uuids.ids({}) %}
{%- set parent = args.parent %}
{%- if parent %}
{%-     if 'service-sets' in parent and parent['service-sets'] %}
{%-         set ss = parent['service-sets'] %}
{%-         for action in [ 'disabled', 'dead', 'enabled', 'running' ] %}
{%-             if action in ss %}
{%-                 with args = {'service_set_names': ss[action], 'action': action } %}
{%                      include('templates/support/servicesets.sls') with context %}
{%-                 endwith %}
{%-             endif %}
{%-         endfor %}
{%-     endif %}
{%-     if 'services' in parent %}
{%-         for action in [ 'disabled', 'dead', 'enabled', 'running' ] %}
{%-             if action in parent.services %}
{%-                 for name in parent.services[action] %}
{%-                     with args = {'service_name': name, 'action': action } %}
{%                          include('templates/support/service.sls') with context %}
{%-                     endwith %}
{%-                 endfor %}
{%-             endif %}
{%-         endfor %}
{%-     endif %}
{%- endif %}
