{#- this template expects the variable 'groupname' to be set #}
{%- if groupname %}

{%-     set group = pillar.groups[groupname] %}

.group-{{groupname}}:
    group.present:
        - name:     {{groupname}}
        - gid:      {{group.gid}}

{%- else %}

.group-not-defined:
    cmd.run:
        - name: echo "ERROR: Salt template 'group' called without parameter 'groupname' defined." 1>&2 ; /bin/false 

{%- endif %}
