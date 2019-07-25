{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set action          = args.action if 'action' in args else 'all' %}
{%- set node_type       = config.type if 'type' in config else 'client' %}
{%- set client_or_server = 'client' if node_type in ['server','master','replica'] else 'client' %}
{%- set scripts = { 
        'common' : [ 'lib-ipa', 'salt-ipa-ticket', 'host-add', 'host-rm', 'user-create', 'update-hosts', 'reset-user-passwd' ],
        'server' : [ 'ipa-pw-upgrade', 'ipa-postinstall', 'ipa-server-backup-job' ],
        'client' : [],
        'master' : []
    } %}

{%- for group_name, script_names in scripts.iteritems() %}
{%-     if group_name in [node_type, client_or_server] %}
{%-         for script_name in script_names %}

{{sls}}.{{deployment_name}}.ipa-common-script-{{group_name}}-{{script_name}}:
    file.managed:
        - name:     /usr/local/bin/{{script_name}}
        - source:   salt://templates/deployment/ipa/scripts/{{script_name}}.sh.jinja
        - user:     root
        - group:    root
        - mode:     '0700'
        - template: jinja
        - context:
            config:            {{config|json}}

{%-         endfor %}
{%-     endif %}
{%- endfor %}

{{sls}}.{{deployment_name}}.ipa-common-sysconfig:
    file.managed:
        - name:     /etc/sysconfig/ipa-tools
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://templates/deployment/ipa/scripts/ipa-tools.sysconfig.jinja
        - template: jinja
        - context:
            config: {{config|json}}
            node_type: {{node_type}}
            client_or_server: {{client_or_server}}

{%- set deploy_script = '/usr/local/bin/deploy-ipa-'~node_type %}
{{sls}}.{{deployment_name}}.ipa-server-script-deploy-ipa-{{node_type}}:
    file.managed:
        - name:     {{deploy_script}}
        - user:     root
        - group:    root
        - mode:     '0700'
        - template: jinja
        - template: |
            #!/bin/bash
            . /usr/local/bin/lib-ipa-deploy.sh
            ipa::deploy::{{node_type}}::main "${@}"
