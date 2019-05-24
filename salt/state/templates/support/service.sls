{%- set prefix, suffix  = salt.uuid.ids(args) %}
{%- set service_name    = args.service_name %}
{%- set action          = args.action if 'action' in args and args.action else '' %}

{%- if service_name and action %}

{{sls}}.{{prefix}}service-{{service_name}}-{{action}}{{suffix}}:
    service.{{'running' if action == 'enabled' else ('dead' if action == 'disabled' else action) }}:
        - name:   {{service_name}}
        {%- if action == 'enabled' %}
        - enable: True
        {%- elif action == 'disabled' %}
        - enable: False
        {%- endif %}

{%- endif %}
