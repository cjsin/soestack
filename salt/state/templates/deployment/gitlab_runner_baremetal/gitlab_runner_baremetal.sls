{%- set prefix, suffix     = salt.uuids.ids(args) %}
{%- set deployment_name    = args.deployment_name %}
{%- set deployment_type    = args.deployment_type %}
{%- set deployment         = args.deployment %}
{%- set config             = args.deployment.config if 'config' in deployment else {} %}
{%- if not config %} 

{{sls}}.{{prefix}}.gitlab-runner-config-missing{{suffix}}:
    noop.notice:
        - text: 'No configuration available for gitlab-runner-baremetal deployment!'

{%-     else %}
{%-     set action             = args.action if 'action' in args else 'all' %}
{%-     set service_name       = 'gitlab-runner' %}
{%-     set prefix             = deployment_type ~ '-' ~ deployment_name ~ '-' ~ action %}
{%-     set registration_token = config.registration_token if 'registration_token' in config and config.registration_token else 'unset' %}
{%-     set run_as_user        = config.run_as if 'run_as' in config else 'gitlab-runner' %}
{%-     set diagnostics        = False %}

{%-     if diagnostics %}
{{sls}}.{{prefix}}.gitlab-runner-config{{suffix}}:
    noop.pprint:
        - data: {{deployment|json}}
{%-     endif %}

{%-     if action in [ 'all', 'install' ] %}
 
{{sls}}.{{prefix}}.gitlab-runner-installed{{suffix}}:
    pkg.installed:
        - fromrepo: gitlab-runner
        - pkgs: 
            - gitlab-runner

{%-     endif %}

{%-     if action in [ 'all', 'configure' ] %}


{%-         if run_as_user not in ['','root'] %}

{%-             if 'working_directory' in config and config.working_directory not in ['','unset'] %}
{{sls}}.{{prefix}}.gitlab-service-home-dir:
    cmd.run:
        - name:   usermod -d '{{config.working_directory}}' '{{run_as_user}}'
        - unless: 'getent passwd gitlab-runner|cut -d: -f6 | grep -Fx "{{config.working_directory}}"'
{%-             endif %}

{%-             if 'executors' in config and config.executors %}
{%-                 set docker_required = [] %}
{%-                 for executor_name, executor in config.executors.iteritems() %}
{%-                     if ('type' in executor and executor['type'] == 'docker') or executor_name in ['docker','docker-dind'] %}
{%-                         do docker_required.append(True) %}
{%-                     endif %}
{%-                 endfor %}
{%-                 if docker_required %}
{{sls}}.{{prefix}}.gitlab-service-user-account-groups-for-docker:
    cmd.run:
        - name: usermod -a -G docker '{{run_as_user}}'
        - unless: groups '{{run_as_user}}' | egrep -q '.*:.* (docker)( |$)'
{%-                 endif %}
{%-             endif %}
{%-         endif %}

{{sls}}.{{prefix}}.gitlab-service-install:
    cmd.run:
        - name:
            gitlab-runner install
              --working-directory '{{config.working_directory}}'
              --user {{run_as_user}}

        - unless: test -f /etc/systemd/system/gitlab-runner.service

{%-         if 'executors' in config and config.executors %}
{%-             if registration_token != 'unset' %}
{%-                 for executor_name, executor in config.executors.iteritems() %}
{%-                     set register_script = '/usr/local/bin/gitlab-runner-register-' ~ executor_name %}
{%-                     set executor_type = executor['type'] if 'type' in executor and executor.type not in ['','unset'] else executor_name %}

{{sls}}.{{prefix}}.gitlab-executor-{{executor_name}}{{suffix}}-{{deployment_name}}-{{deployment_type}}-register-script:
    file.managed:
        - name: '{{register_script}}'
        - mode: '0700'
        - user: 'root'
        - group: 'root'
        - source: salt://templates/deployment/gitlab_runner_baremetal/gitlab-runner-register-executor.sh.jinja
        - template: jinja
        - context:
            json: |
                {{config|json}}
            config: {{config|json}}
            executor: {{executor}}
            executor_name: {{executor_name}}
            executor_type: {{executor_type}}

{{sls}}.{{prefix}}.gitlab-executor-{{executor_name}}{{suffix}}-{{deployment_name}}-{{deployment_type}}-register:
    cmd.run:
        - name:  '{{register_script}}'
        - unless: grep {{grains.host}}-{{executor_name}} /etc/gitlab-runner/config.toml
    
{%-                 endfor %}
{%-             else %}

{{sls}}.gitlab-runner-baremetal.{{deployment_name}}-registration-token-not-set:
    noop.warning:
        - text: |
            The gitlab runner for {{deployment_name}} has no registration token set. 
            Run the state again after updating the configured token value.

{%-             endif %}
{%-         else %}

{{sls}}.gitlab-runner-baremetal.{{deployment_name}}.no-executors-configured:
    noop.notice:
        - text: The gitlab runner for {{deployment_name}} has no executors configured.

{%-         endif %}
{%-     endif %}

{%-     if action in [ 'all', 'activate' ] %}
{%-         set activated = 'activated' in deployment and deployment.activated %}

{{sls}}.{{prefix}}.{{service_name}}-service{{suffix}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{service_name}} 
        - enable: {{activated}} 

{%-     endif %}
{%- endif %}
