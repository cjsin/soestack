{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set pwfile          = '/etc/sysconfig/ipa-passwords' %}
{%- set pwusers         = [ 'master', 'admin', 'ds' ] %}

# Generate some (possibly random) passwords, and then upgrade them 
# to be salt-secrets.

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
            {%- for pw_name in pwusers %}
            {{pw_name}}_password="{{config.passwords[pw_name] if 'passwords' in config and pw_name in config.passwords and config.passwords[pw_name] != 'random' else salt['random'].get_str(10)}}"
            {%- endfor %}

{{sls}}.{{deployment_name}}.ipa-master-deploy-passwords-store-as-secrets:
    cmd.run:
        - name:   /usr/local/bin/ipa-pw-upgrade
        - onlyif: grep -sv '=salt-secret:' '{{pwfile}}'
