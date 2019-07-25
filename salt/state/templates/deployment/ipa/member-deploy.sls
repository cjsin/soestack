{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set node_type       = config.type if 'type' in config else 'client' %}
{%- set client_or_server = 'server' if node_type in ['server','master','replica'] else 'client' %}

{{sls}}.{{deployment_name}}.deploy:
    cmd.run:
        - name:     /usr/local/bin/deploy-ipa-{{node_type}}
        - unless:   test -f /var/log/ipa{{client_or_server}}-install.log && ! test -f /var/log/ipa{{client_or_server}}-install.FAILED
