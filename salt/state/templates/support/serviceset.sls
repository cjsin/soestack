{#
#
# This template requires:
#    - args, containing:
#      - service_set_name  - the service set name
#      - service_set       - the service set object (contains a list of service names)
#      - action  (defaults to 'enabled', but may be 'enabled','disabled','dead','running'
#          - dead and running will use salt 'dead' and 'running' but will not set the 'enable' flag either on or off
#          - disabled and enabled equate to dead and running but will also set the 'enable' flag.
#
#}
{%- set service_set_name = args.service_set_name %}
{%- set service_set = args.service_set %}
{%- set action      = args.action if 'action' in args else '' %}

{%- if service_set and action %}
{%-     for os_items, service_names in service_set.iteritems() %}
{%-         if grains.os.lower() in os_items.split(',') %}
{%-             for service_name in service_names %}
{%-                 with args = { 'service_name': service_name, 'action': action, 'prefix': 'service-set-' ~ service_set_name } %}
{%                      include('templates/support/service.sls') with context %}
{%-                 endwith %}
{%-             endfor %}
{%-         endif %}
{%-     endfor %}
{%- endif %}
