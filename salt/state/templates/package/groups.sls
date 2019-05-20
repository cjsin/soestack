
#
# Expected context variables:
# 
# args:  a dict with *one of* the following keys/values:
#    
#    - package_set:   <name of a package set>
#    - package_sets:  <array of package set names>
#
# Example pillar data:
#
# package-groups:
#    basic-node:
#        purpose: |
#            provide basic tools that an admin will expect on most nodes
#        package-groups:
#            - minimal-node
#        package-sets:
#            - net-tools

#
# Example salt usage:
#   set args = { 'package_group': 'net-tools' }
#   include('templates/package/sets.sls') with context
#   set args = { 'package_groups': ['net-tools','console-tools'] }
#   include('templates/package/sets.sls') with context
#   set args = { 'package_groups': 'net-tools,console-tools' }
#   include('templates/package/sets.sls') with context
#
{%- set suffix = salt['cmd.exec_code']('python','import uuid; print(str(uuid.uuid4())); ')[:8] %}
{%- set diagnostics = False %}

{%- if 'package-groups' in pillar 
    and ('package_groups' in args 
        or 'package_group' in args 
        or 'package_group_names' in args 
        or 'package_group_name' in args
        )  
        %}

{%-     set ppg = pillar['package-groups'] %}

{#-     # process basic names #}
{%-     set gathered_names = [] %}
{%-     if 'package_groups_names' in args %}
{%-         if args.package_group_names is not string %}
{%-             do gathered_names.extend(args.package_group_names) %}
{%-         else %}
{%-             do gathered_names.extend(args.package_group_names.split(',')) %}
{%-         endif %}
{%-     endif %}
{%-     if 'package_group_name' in args %}
{%-         do gathered_names.extend(args.package_group_name.split(',')) %}
{%-     endif %}

{#-     # process objects #}
{%-     set gathered_objects = [] %}
{%-     if 'package_groups' in args %}
{%-         do gathered.extend(args.package_groups) %}
{%-     endif %}
{%-     if 'package_group' in args %}
{%-         do gathered.extend([args.package_group]) %}
{%-     endif %}


{%-     if diagnostics and not gathered_names and not gathered_objects %}

missing-parameters-for-install_package_groups-{{suffix}}:
    cmd.run:
        - name: |
            echo "Neither arg 'package_group_name(s)' or 'package_group(s)' was specified."
            exit 1

{%-     endif %}


{%-     for package_group in gathered_objects %}
{%-         set args = { 'package_group': package_group } %}
{%          include('templates/package/group.sls') with context %}
{%-     endfor %}

{%-     for package_group_name in gathered_names %}

{%-         if diagnostics and package_group_name not in ppg %}

unrecognised-package-group-name-{{package_group_name}}-{{suffix}}:
    cmd.run:
        - name: |
            echo "Specified package group name was not defined in pillar."
            exit 1

{%-         endif %}

{%-         if package_group_name in ppg %}

{%-             set args = { 'package_group': ppg[package_group_name] } %}
{%              include('templates/package/group.sls') with context %}

{#-         # end if the name was found #}
{%-         endif %}

{#-     # end for each gathered name #}
{%-     endfor %}

{#- # endif pillar support available and the required args were specified #}
{%- endif %}
