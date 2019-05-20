
{% set args = { 'package_group_name': 'kubernetes-node' } %}
{% include('templates/package/groups.sls') with context %}
