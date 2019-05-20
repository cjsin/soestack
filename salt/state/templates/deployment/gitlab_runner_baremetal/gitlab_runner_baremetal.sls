{%- set prefix, suffix  = salt.uuid.ids(args) %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment_type = args.deployment_type %}
{%- set deployment      = args.deployment %}
{%- set config          = args.deployment.config %}
{%- set action          = args.action if 'action' in args else 'all' %}
{%- set service_name    = deployment_name %}
{%- set prefix          = deployment_type ~ '-' ~ deployment_name ~ '-' ~ action %}

{%- if action in [ 'all', 'install' ] %}
 
{{prefix}}gitlab-runner-installed{{suffix}}:
    pkg.installed:
        - pkgs: 
            - gitlab-runner

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{%-     for executor_name, executor in config.executors.iteritems() %}

{{prefix}}gitlab-executor-{{executor_name}}{{suffix}}-{{deployment_name}}-{{deployment_type}}:
    cmd.run:
        - name: |
            options=(
                --non-interactive 
                --name               {{grains.host}}-{{executor_name}}
                --url                http://{{config.gitlab_host}}
                --executor           {{executor_name}}
                --registration-token {{config.registration_token}} 
                {{config.registration_flags|join(" ")}} 
                {{executor.registration_flags|join(" ")}}
            )
            gitlab-runner register "${options[@]}"

        - unless: grep {{grains.host}}-{{executor_name}} /etc/gitlab-runner/config.toml
    
{%-     endfor %}
{%- endif %}

{%- if action in [ 'all', 'activate' ] %}
{%-     set activated = 'activated' in deployment and deployment.activated %}

{{prefix}}{{service_name}}-service{{suffix}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{service_name}} 
        - enable: {{activated}} 

{%- endif %}
