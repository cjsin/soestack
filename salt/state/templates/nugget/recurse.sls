#
#  The following variables are expected:
#     - nugget_name
#     - nugget
#     - required - the list of other required nuggets
#     - action - one of 'install' or 'activate'
{%  import 'lib/noop.sls' as noop %}

{%- set diagnostics = False %}
{%- set nugget_name = args.nugget_name %}
{%- set nugget      = args.nugget %}
{%- set required    = args.required if 'required' in args and args.required else [] %}
{%- set action      = args.action if 'action' in args and args.action else '' %}

{%- if required and action in ['install','activate'] %}

{%- if diagnostics %}
{{noop.notice(action ~' pulling in nuggets ' ~ ','.join(required))}}
{%- endif %}

{%-     for name in required %}
{%-         with args = {'nugget_name': name, 'required_by': nugget_name} %}
{%              include('templates/nugget/'~action~'.sls') with context %}
{%-         endwith %}
{%-     endfor %}

{%- endif %}
