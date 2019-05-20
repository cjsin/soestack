{%- set diagnotics = False %}
{%- set configue_args = {} %}
{%- do configue_args.update(args) %}
{%- do configue_args.update({'action': 'configure'}) %}

{%- with args = configue_args %}

{%- if diagnostics %}
{{ noop.pprint('configure action with args', args) }}
{%- endif %}

{%      include('templates/nugget/action.sls') with context %}
{%- endwith %}
