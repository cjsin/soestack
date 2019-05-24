#!stateconf yaml . jinja

{#
# 
# How this works:
# 
# 'role-set' grain:
#    - this grain can contain the name of a role-set (matching one defined in pillar)
#    which will be expanded into a list of roles.
# 'roles' grain:
#    - this grain is an array of role names (matching those defined in pillar).
#
#
# For example, the role-set might be set to 'developer-workstation-node' which
# then causes 'roles' to have appended the values 'workstation-node' and 'software-development-node'
#
#}


{%- if 'role-sets' in pillar and pillar['role-sets'] %}
{%-     set rolesets = pillar['role-sets'] %}

{%-     if 'role-set' in grains and grains['role-set'] %}

{%-         if grains['role-set'] in rolesets %}

{%-             set roleset_name = grains['role-set'] %}
{%-             set roleset_object = rolesets[roleset_name] %}
{%-             if 'combine' in roleset_object and roleset_object.combine %}
{%-                 set current_roles = [] + grains.roles if 'roles' in grains else [] %}
{%-                 for role in roleset_object.combine %}
{%-                     if role not in current_roles %}
{%-                         do current_roles.append(role) %}
{%-                     endif %}
{%-                 endfor %}

#.display-updated-roles:
#    noop.notice:
#        - name: {{','.join(current_roles)}}

# Old roles grain is deleted because
# salt fails to overwrite grains if it is a complex object,
# even when the force flag is set to True

{#- # The grains.absent, grains.present states report 'changed' even when no change was made #}
{#- # So we take some effort here to only include it if necessary #}

{%-                 if 'roles' not in grains or grains.roles|join(',') != current_roles|join(',') %}

{%-                     if 'roles' in grains %}
.delete-old-roles-grain:
    grains.absent:
        - name:   roles
        - force:  True
{%-                     endif %}

.update-roles-for-roleset-{{roleset_name}}:
    grains.present:
        - name:   roles
        - force:  True
        - value:  {{current_roles|json}}
{%-                 else %}

.no-roles-change:
    noop.notice:
        - text: |
            grains.roles = {{grains.roles|join(",")}}
            current_roles = {{current_roles|join(",")}}

{%-                 endif %}

{%-             else %}

.invalid-or-empty-role-set:
    noop.notice:
        - name: The role-set '{{roleset_name}}' does not declare a list of combined roles

{#-             end if the role set correctly defines which roles it combines #}
{%-             endif %}

{%-         else %}

.unrecognised-roleset-grain:
    noop.notice:
        - name: The role-set grain '{{grains['role-set']}}' does not match a role set defined in pillar.

{%-         endif %}

{%-     else %}

.no-roleset-grain:
    noop.notice:
        - name: There is no role-set grain assigned to this node

{#-     end if a role-set grain is assigned to this node #}
{%-     endif %}

{%- else %}

.no-pillar-support:
    noop.notice:
        - name: There is no pillar support for role-sets, or a pillar include failed.

{#- end if pillar has support for role-sets #}
{%- endif %}
