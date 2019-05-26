{%- set package_group      = args.package_group %}

{%- set suffix = salt['uuid.short']() %}

{# # support recursion #}
{%- if 'package-groups' in package_group %}

{%-     set args = { 'package_group_names': package_group['package-groups'] } %}
{%      include('templates/package/groups.sls') with context %}

{%- endif %}

{%- if 'package-sets' in package_group %}

{%-     set args = { 'package_set_names': package_group['package-sets'] } %}
{%      include('templates/package/sets.sls') with context %}

{%- endif %}
