#!stateconf yaml . jinja 

{%- set groupname = 'node_exporter' %}
{%- set group = pillar.accounts.groups[groupname] %}
{%- set username = 'node_exporter' %}
{%- set user = pillar.accounts.users[username] %}

{# # Create groups manually until I can get the jinja template include to find the right path  #}

.group-{{groupname}}:
    group.present:
        - name:     {{groupname}}
        - system:   True

.user-account-{{username}}:
    user.present:
        - name:     {{username}}
        - fullname: {{user.fullname}}
        - shell:    {{user.shell}}
        - home:     {{user.home}}
        - createhome: False
        - system:     True
        - groups:
            {%- for group in user.groups %}
            - {{group}}
            {%- endfor %}

