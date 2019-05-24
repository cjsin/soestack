{#- this template expects the variable 'groupname' to be set #}
{%- if groupname %}

{%-     set group = pillar.groups[groupname] %}

{{sls}}.{{groupname}}.group:
    group.present:
        - name:     {{groupname}}
        - gid:      {{group.gid}}

{%- else %}

{{sls}}.group-not-defined:
    noop.error:
        - text: |
            Salt template 'group' called without parameter 'groupname' defined.

{%- endif %}
