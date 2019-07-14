{%- set prefix, suffix     = salt.uuids.ids(args) %}
{%- set deployment_name    = args.deployment_name %}
{%- set deployment_type    = args.deployment_type %}
{%- set deployment         = args.deployment %}
{%- set config             = args.deployment.config if 'config' in deployment else {} %}
{%- if not config %} 

{{sls}}.{{prefix}}gitlab-runner-config-missing{{suffix}}:
    noop.notice:
        - text: 'No configuration available for gitlab-runner-baremetal deployment!'

{%- else %}
{%- set action             = args.action if 'action' in args else 'all' %}
{%- set service_name       = deployment_name %}
{%- set prefix             = deployment_type ~ '-' ~ deployment_name ~ '-' ~ action %}
{%- set registration_token = config.registration_token if 'registration_token' in config and config.registration_token else 'unset' %}
{%- set diagnostics        = False %}

{%- if diagnostics %}
{{sls}}.{{prefix}}gitlab-runner-config{{suffix}}:
    noop.pprint:
        - data: {{deployment|json}}
{%- endif %}

{%- if action in [ 'all', 'install' ] %}
 
{{sls}}.{{prefix}}gitlab-runner-installed{{suffix}}:
    pkg.installed:
        - pkgs: 
            - gitlab-runner

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{%-     if 'executors' in config and config.executors %}
{%-         if registration_token != 'unset' %}
{%-             for executor_name, executor in config.executors.iteritems() %}

{{sls}}.{{prefix}}gitlab-executor-{{executor_name}}{{suffix}}-{{deployment_name}}-{{deployment_type}}:
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
    
{%-             endfor %}
{%-         else %}

{{sls}}.gitlab-runner-baremetal.{{deployment_name}}.registration-token-not-set:
    noop.warning:
        - text: The gitlab runner for {{deployment_name}} has no registration token set. Run the state again after updating the configured token value.

{%-         endif %}
{%-     else %}

{{sls}}.gitlab-runner-baremetal.{{deployment_name}}.no-executors-configured:
    noop.notice:
        - text: The gitlab runner for {{deployment_name}} has no executors configured.

{%-     endif %}
{%- endif %}

{%- if action in [ 'all', 'activate' ] %}
{%-     set activated = 'activated' in deployment and deployment.activated %}

{{sls}}.{{prefix}}{{service_name}}-service{{suffix}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{service_name}} 
        - enable: {{activated}} 

{%- endif %}
{%- endif %}
