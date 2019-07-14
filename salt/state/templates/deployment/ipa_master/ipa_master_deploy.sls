{#  this should be ipa_master - IPA does not have masters, just equal replicas #}
{#  however we are using the term master for an 'initial' server deployment #}

{#- save the deployment args for reuse when including ipa_common #}
{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set action          = args.action if 'action' in args else 'all' %}
{%- set deployment_type = args.deployment_type %}
{%- set pwfile          = '/etc/sysconfig/ipa-passwords' %}

{#- configuration/deployment specific to the first ipa server instance #}

{%- if action in [ 'all', 'configure' ] %}

{%-     set scripts = { '' : [ 'deploy-ipa-server','ipa-pw-upgrade' ] } %}
{%-     for script_suffix, script_names in scripts.iteritems() %}
{%-         for script_prefix in script_names %}

{{sls}}.{{deployment_name}}.ipa-master-script-{{script_prefix}}:
    file.managed:
        - name:     /usr/local/bin/{{script_prefix}}{{script_suffix}}
        - source:   salt://{{slspath}}/scripts/{{script_prefix}}.sh.jinja
        - user:     root
        - group:    root
        - mode:     '0700'
        - template: jinja
        - context:
            deployment_name:   '{{deployment_name}}'
            config:            {{config|json}}

{%-         endfor %}
{%-     endfor %}

{{sls}}.{{deployment_name}}.ipa-master-deploy-passwords-generate-random:
    file.managed:
        - name:     {{pwfile}}
        - user:     root
        - group:    root
        - mode:     '600'
        # NOTE the file is only generated if it does not exist because
        # we don't want to overwrite it with different random passwords
        # NOTE also that any plain text passwords written here are then
        # protected by encryption afterwards using the salt-secret command
        - unless:   test -f "{{pwfile}}"
        - contents: |
            {%- for pw_name in [ 'master', 'admin', 'ds' ] %}
            {{pw_name}}_password="{{config.passwords[pw_name] if 'passwords' in config and pw_name in config.passwords and config.passwords[pw_name] != 'random' else salt['random'].get_str(10)}}"
            {%- endfor %}

{{sls}}.{{deployment_name}}.ipa-master-deploy-passwords-store-as-secrets:
    cmd.run:
        - name:   /usr/local/bin/ipa-password-upgrade
        - onlyif: grep -sv '=salt-secret:' '{{pwfile}}'

{#- # configure action #}
{%- endif %}

{%- if action in [ 'all', 'activate' ] %}
{%-     set activated = 'activated' in deployment and deployment.activated %}
{%-     if activated %}

{{sls}}.{{deployment_name}}.deploy:
    cmd.run:
        - name:     /usr/local/bin/deploy-ipa-server
        - unless:   test -f /var/log/ipaserver-install.log && ! test -f /var/log/ipaserver-install.FAILED

{%-     endif %}
{%- endif %}

