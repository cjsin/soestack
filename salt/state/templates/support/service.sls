{%- set prefix, suffix  = salt.uuids.ids(args) %}
{%- set service_name    = args.service_name %}
{%- set action          = args.action if 'action' in args and args.action else '' %}

{%- if service_name and action %}

{%-     if action == 'masked' %}

{{sls}}.{{prefix}}service-{{service_name}}-{{action}}{{suffix}}:
    cmd.run:
        # - name: ln -sf /dev/null /etc/systemd/system/{{service_name}}.service 
        - name:   systemctl mask '{{service_name}}' 
        - unless: systemctl is-enabled '{{service_name}}' | egrep '^masked$'

{%-     else %}

{{sls}}.{{prefix}}service-{{service_name}}-{{action}}{{suffix}}:
    service.{{'running' if action == 'enabled' else ('dead' if action == 'disabled' else action) }}:
        - name:   {{service_name}}
        {%- if action == 'enabled' %}
        - enable: True
        {%- elif action == 'disabled' %}
        - enable: False
        {%- endif %}

{%-     endif %}
{%- endif %}
