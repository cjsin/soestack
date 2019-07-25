{#
# This template expects the following vars:
#  args: a dict with the following keys:
#     - deployment_name   - the name of the deployment
#     - deployment        - the deployment object (should contain a container object)
#}

{%- set deployment = args.deployment %}
{%- set deployment_name = args.deployment_name %}
{%- set action = args.action if 'action' in args else 'all' %}
{%- set container = deployment.container %}

{%- if action in ['all', 'install' ] %}

{#- NOTE that this file installation is done in the install stage not the configure stage #}
{#- in order that it is present before the containerized_service deployment runs #}

{{sls}}.nginx_container.conf-{{deployment_name}}:
    file.managed:
        - name:     /etc/nginx/{{deployment_name}}.conf
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://{{slspath}}/{{deployment_name}}.conf.jinja
        - template: jinja
        - context:
            deployment_name: {{deployment_name}}
            deployment:      {{deployment|json}}
            container:       {{container|json}}

{%- endif %}
