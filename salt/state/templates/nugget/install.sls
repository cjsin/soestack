{%- set install_args = {} %}
{%- do install_args.update(args) %}
{%- do install_args.update({'action': 'install'}) %}
{%- with args = install_args %}
{%      include('templates/nugget/action.sls') with context %}
{%- endwith %}
