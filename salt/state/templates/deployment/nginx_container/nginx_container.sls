{#
# This template expects the following vars:
#  args: a dict with the following keys:
#     - deployment_name   - the name of the deployment
#     - deployment        - the deployment object (should contain a container object)
#}

{%- set container = args.deployment.container %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment = args.deployment %}

{{sls}}.nginx_container.cfgdir:
    file.directory:
       - name:      /etc/nginx
       - user:      root
       - group:     root
       - mode:      '0755'

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

{%  include('templates/containerized_service/containerized_service.sls') with context %}

