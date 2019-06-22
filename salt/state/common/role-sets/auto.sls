#!stateconf yaml . jinja 

{%- if 'node_maps' in pillar and pillar.node_maps is mapping and grains.host in pillar.node_maps %}
{%-     set data = pillar.node_maps[grains.host] %}
{%-     if 'roles' in data and data.roles %}
{%-         set specified_roles = data.roles %}
{%-         set current_roles = [] %}

{%-         if specified_roles is string %}
{%-             if ':' in specified_roles and specified_roles.split(':')[0] == 'role-set'  %}
{%-                 set rolesets = pillar['role-sets'] %}
{%-                 set roleset_name = specified_roles.split(':')[1] %}
{%-                 if roleset_name in rolesets %}
{%-                     set roleset_object = rolesets[roleset_name] %}
{%-                     if 'combine' in roleset_object and roleset_object.combine %}
{%-                         for role in roleset_object.combine %}
{%-                             if role not in current_roles %}
{%-                                 do current_roles.append(role) %}
{%-                             endif %}
{%-                         endfor %}
{%-                     endif %}
.roleset-grain-present-{{roleset_name}}:
    grains.present:
        - name: role-set
        - value: '{{roleset_name}}'
{%-                 else %}
.roleset-{{roleset_name}}-not-defined-in-pillar:
    noop.notice:
        - text: |
            The selected role-set '{{roleset_name}}' is not mapped to a list of roles in pillar data
{%-                 endif %}
{%-             else %}
{%-                 do current_roles.append(specified_roles) %}
{%-             endif %}
{%-         elif data is iterable %}
{%-             do current_roles.extend(specified_roles) %}
{%-         endif %}

{%-         if current_roles %}
{%-             if 'roles' in grains and grains.roles|join(',') != current_roles|join(',') %}
.delete-old-roles-grain:
    grains.absent:
        - name:   roles
        - force:  True
{%-              endif %}

.update-roles:
    grains.present:
        - name:   roles
        - force:  True
        - value:  {{current_roles|json}}

{#-         # end if a roles list was specified #}
{%-         endif %}

{#-     # end if roles in node map data #}
{%-     endif %}

{#- # end if pillar has support for node-maps #}
{%- endif %}
