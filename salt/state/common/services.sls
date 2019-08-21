#!stateconf yaml . jinja

{%- if 'service-status' in pillar and pillar['service-status'] %}
{%-     set services = pillar['service-status'] %}

{%-     with args = { 'parent': services } %}
{%-         include('templates/support/services.sls') with context %}
{%-     endwith %}

{#- Old implementation, disabled in favour of templates/support/services #}
{%- if False %}
{%-     if 'disabled' in services %}
{%-         for service_name in services.disabled %}
.disable-service-{{service_name}}:
    service.dead:
        - name:    {{service_name}}
        - enable:  False
{%-         endfor %}
{%-     endif %}
{%-     if 'enabled' in services %}
{%-         for service_name in services.enabled %}
.enable-service-{{service_name}}:
    service.running:
        - name:    {{service_name}}
        - enable:  True
{%-         endfor %}
{%-     endif %}
{%- endif %}


{%- endif %}
