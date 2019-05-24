{#- this template expects the variable 'username' to be set #}
{%- if username %}

{%-     set user = pillar.users[username] %}

{{sls}}.{{username}}.user-account:
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

{{sls}}.{{username}}.user-account-not-defined:
    noop.error:
        - text: |
            Salt template 'user' called without parameter 'username' defined.

{%- endif %}
