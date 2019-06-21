#!stateconf yaml . jinja 

{#  first install packages based on the configured roles #}

{%- set diagnostics = True %}

{%- if 'roles' in grains %}
{%-     for role_name in grains.roles %}
{%-         if role_name in pillar['package-groups'] %}
{%-             set args = { 'package_group_name': role_name } %}

{%- if diagnostics %}

{{sls}}.pulling-in-package-group-for-role-{{role_name}}:
    noop.notice

{%- endif %}

{%              include('templates/package/groups.sls') with context %}
{%-         else %}

{{sls}}.no-package-group-for-role-{{role_name}}:
    noop.notice:
        - text: There is no package group defined for role '{{role_name}}'

{%-         endif %}
{%-     endfor %}
{%- endif %}

{#  Next, install packages specifically called for in the pillar data #}

{%- if 'selected_packages' in pillar %}
{%-     for item in pillar.selected_packages %}
{%-         if 'package-groups' in pillar and item in pillar['package-groups'] %}
{%-             set args = { 'package_group_name': item } %}
{%              include('templates/package/groups.sls') with context %}
{%-         endif %}
{%-         if 'package-sets' in pillar and item in pillar['package-sets'] %}
{%-             set args = { 'package_set_name': item } %}
{%              include('templates/package/sets.sls') with context %}
{%-         endif %}
{%-     endfor %}
{%- endif %}
