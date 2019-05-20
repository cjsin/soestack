#!stateconf yaml . jinja 

{%- set groupname = 'grafana' %}
{%- set group = pillar.accounts.groups[groupname] %}
{%- set username = 'grafana' %}
{%- set user = pillar.accounts.users[username] %}

# Create groups manually until I can get the jinja template include to find the right path 

.group-{{groupname}}:
    group.present:
        - name:     {{groupname}}
        # - system:   True
        - gid:      {{group.gid}}

.user-account-{{username}}:
    user.present:
        - name:     {{username}}
        - fullname: {{user.fullname}}
        # - system:   True
        - uid:      {{user.uid}}
        - shell:    {{user.shell}}
        - home:     {{user.home}}
        - createhome: False
        - groups:
            {%- for group in user.groups %}
            - {{group}}
            {%- endfor %}

