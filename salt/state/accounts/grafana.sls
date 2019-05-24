#!stateconf yaml . jinja 

{%- set groupname = 'grafana' %}
{%- set group = pillar.accounts.groups[groupname] %}
{%- set username = 'grafana' %}
{%- set user = pillar.accounts.users[username] %}
{%- set diagnostics = False %}

{# # Create groups manually until I can get the jinja template include to find the right path  #}

{%- if diagnostics %}
.will-create-group-{{groupname}}-with-gid-{{group.gid}}:
    noop.notice
{%- endif %}

.group-{{groupname}}:
    group.present:
        - name:     {{groupname}}
        {%- if 'gid' in group and group.gid is defined %}
        # - system:   True
        - gid:      {{group.gid}}
        {%- endif %}

{%- if diagnostics %}
.will-create-user-{{username}}-with-uid-{{user.uid}}:
    noop.notice
{%- endif %}

.user-account-{{username}}:
    user.present:
        - name:     {{username}}
        - fullname: {{user.fullname}}
        # - system:   True
        - uid:      {{user.uid}}
        - shell:    {{user.shell}}
        - home:     {{user.home}}
        - createhome: False
        {%- if 'gid' in group and group.gid is defined %}
        - gid:      {{group.gid}}
        {%- endif %}
        - groups:
            {%- for group in user.groups %}
            - {{group}}
            {%- endfor %}

