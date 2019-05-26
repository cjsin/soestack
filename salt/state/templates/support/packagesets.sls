{#
# This template requires already defined:
#    - args, containing 'parent'
#}
{%- set parent = args.parent %}
{%- if parent %}
{%-     for action in ['absent','installed'] %}
{%-         if action in parent %}
{%-             for style in ['package-groups','package-sets'] %}
{%-                 if style in parent[action] %}
{%-                     for name in parent[action][style] %}
{%-                         if style == 'package-groups' %}
{%-                             with args = { 'package_group_name': name, 'action': action } %}
{%                                  include('templates/package/groups.sls') with context %}
{%-                             endwith %}
{%-                         elif style == 'package-sets' %}
{%-                             with args = { 'package_set_name': name, 'action': action } %}
{%                                  include('templates/package/sets.sls') with context %}
{%-                             endwith %}
{%-                         endif %}
{%-                     endfor %}
{%-                 endif %}
{%-             endfor %}
{%-         endif %}
{%-     endfor %}
{%- endif %}
