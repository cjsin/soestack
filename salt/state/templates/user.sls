{#- this template expects the variable 'username' to be set #}
{%- if username %}

{%-     set user = pillar.users[username] %}

.user-account-{{username}}:
    user.present:
        - name:     {{username}}
        - fullname: {{user.fullname}}
        {%- if 'home' in user %}
        - home:     {{user.home}}
        {%- endif %}
        - uid:      {{user.uid}}
        - groups:
            {%- for group in user.groups %}
            - {{group}}

{%- else %}

.user-account-not-defined:
    cmd.run:
        - name: echo "ERROR: Salt template 'user' called without parameter 'username' defined." 1>&2 ; /bin/false 

{%- endif %}
