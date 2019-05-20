{%- set activate_args = {} %}
{%- do activate_args.update(args) %}
{%- do activate_args.update({'action':'activate'}) %}
{%- with args = activate_args %}
{%      include('templates/nugget/action.sls') with context %}
{%- endwith %}
