{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}

{{sls}}.{{deployment_name}}.postinstall:
    cmd.run:
        - name: /usr/local/bin/ipa-postinstall --auto
        - unless: test -f /var/log/ipa-postinstall.log.success

