#!stateconf yaml . jinja 

{%- if 'node_maps' in pillar and pillar.node_maps is mapping %}
{%-     if grains.host in pillar.node_maps %}
{%-         set current_roles   = [] %}
{%-         set data = pillar.node_maps[grains.host] %}
{%-         if 'roles' in data and data.roles %}
{%-             set specified_roles = data.roles %}

{%-             if specified_roles is string %}
{%-                 if ':' in specified_roles %}
{%-                     if specified_roles.split(':')[0] == 'role-set' %}
{%-                         set rolesets = pillar['role-sets'] %}
{%-                         set roleset_name = specified_roles.split(':')[1] %}
{%-                         if roleset_name in rolesets %}
{%-                             set roleset_object = rolesets[roleset_name] %}
{%-                             if 'combine' in roleset_object and roleset_object.combine %}
{%-                                 for role in roleset_object.combine %}
{%-                                     if role not in current_roles %}
{%-                                         do current_roles.append(role) %}
{%-                                     endif %}
{%-                                 endfor %}
{%-                             endif %}
{%-                         else %}
.roleset-{{roleset_name}}-not-defined-in-pillar:
    noop.notice:
        - text: |
            The selected role-set '{{roleset_name}}' is not mapped to a list of roles in pillar data
{%-                         endif %}
.roleset-grain-present-{{roleset_name}}:
    grains.present:
        - name:  role-set
        - value: '{{roleset_name}}'
{%-                     else %}
.roles-format-unrecognised-colon:
    noop.notice:
        - text: The specified role-set has a colon but does not start with role-set
{%-                     endif %}
{%-                 else %}
{%-                     do current_roles.extend(specified_roles.split(',')) %}
{%-                 endif %}
{%-             elif data is iterable and data is not mapping %}
{#-                 # the roles value is iterable and is not a string #}
{%-                 do current_roles.extend(specified_roles) %}
{%-             else %}
.roleset-data-format-unrecognised:
    noop.notice:
        - text: The roles specified for {{grains.host}} is not a string or list
{%-             endif %}

{%-             if current_roles %}
{%-                 if 'roles' in grains and grains.roles|join(',') != current_roles|join(',') %}
.delete-old-roles-grain:
    grains.absent:
        - name:   roles
        - force:  True
{%-                 endif %}

.update-roles:
    grains.present:
        - name:   roles
        - force:  True
        - value:  {{current_roles|json}}

{%-             else %}

.no-role-data:
    noop.notice:
        - text: The generated list of nodes was empty

{#-             # end if some roles were generated #}
{%-             endif %}

{%-         else %}

.no-role-data:
    noop.notice:
        - text: The node_maps data for host {{grains.host}} does not include roles information

{#-         # end if roles in node map data #}
{%-         endif %}

{%-     else %}

.host-{{grains.host}}-not-found-in-node-maps:
    noop.notice:
        - text: |
            this host {{grains.host}} was not found in:
            {{pillar.node_maps|json}}
{%-     endif %}
{%- else %}

.node-maps-data-not-found-in-pillar:
    noop.notice:
        - text: Auto selection of roles/role-sets not availale (no node_maps in pillar)

{#- # end if pillar has support for node-maps #}
{%- endif %}
