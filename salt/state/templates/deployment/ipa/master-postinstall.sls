{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}

{{sls}}.{{deployment_name}}.postinstall:
    cmd.run:
        - name:     /usr/local/bin/ipa-postinstall
