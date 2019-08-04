{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set action          = args.action if 'action' in args else 'all' %}
{%- set node_type       = config.type if 'type' in config else 'client' %}
{%- set client_or_server = 'server' if node_type in [ 'server', 'master', 'replica' ] else 'client' %}
{%- set scripts = { 
        'common' : [ 
            'salt-ipa-ticket', 
            'host-add', 
            'host-rm', 
            'host-rebuild',
            'user-create', 
            'update-hosts', 
            'reset-user-passwd',
            'deploy-ipa',
            'lib-ipa-deploy'
            ],
        'server' : [ 
            'ipa-pw-upgrade', 
            'ipa-postinstall', 
            'ipa-server-backup',
            'ipa-reset-admin-password',
            'ipa-reset-ds-password'
            ],
        'client' : [],
        'master' : []
    } %}

{%- for group_name, script_names in scripts.iteritems() %}
{%-     if group_name in [ 'common', node_type, client_or_server ] %}
{%-         for script_name in script_names %}
{%-             set suffix = '.sh' if script_name.startswith('lib-') else '' %}

{{sls}}.{{deployment_name}}.member-script.{{group_name}}.{{script_name}}-for-{{group_name}}-{{node_type}}-{{client_or_server}}:
    file.managed:
        - name:     /usr/local/bin/{{script_name}}{{suffix}}
        - source:   salt://templates/deployment/ipa/scripts/{{script_name}}.sh.jinja
        - user:     root
        - group:    root
        - mode:     '0700'
        - template: jinja
        - context:
            config:    {{config|json}}
            node_type: '{{node_type}}'
            client_or_server: '{{client_or_server}}'
            deployment_name: '{{deployment_name}}'

{%-         endfor %}
{%-     endif %}
{%- endfor %}

{{sls}}.{{deployment_name}}.member-script.sysconfig:
    file.managed:
        - name:     /etc/sysconfig/ipa-tools
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://templates/deployment/ipa/scripts/ipa-tools.sysconfig.jinja
        - template: jinja
        - context:
            config:           {{config|json}}
            node_type:        {{node_type}}
            client_or_server: {{client_or_server}}
            deployment_name: '{{deployment_name}}'
