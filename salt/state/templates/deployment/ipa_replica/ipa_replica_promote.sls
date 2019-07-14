{#- save the deployment args for reuse when including ipa_common #}
{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}

{#  this should be ipa_replica - IPA does not have masters, just equal replicas #}
{#  however we are using the term master for an 'initial' server deployment #}
{#  and replica for another server which is joined with an existing master #}

{{sls}}.ipa-replica-install-script-{{deployment_name}}:
    file.managed:
        - name:         /usr/local/bin/ipa-replica-deploy
        - source:       salt://{{slspath}}/deploy-ipa-replica.sh.jinja
        - user:         root
        - group:        root
        - mode:         '0755'
        - template:     jinja
        - context:
            name:             {{deployment_name}}
            config:           {{config|json}}
        
{{sls}}.ipa-replica-join-{{deployment_name}}:
    cmd.run:
        - name:    /usr/local/bin/ipa-replica-deploy
        # TODO - check the log file names
        - unless:  test -f /var/log/ipaserver-install.log
        - creates: /var/log/ipaserver-install.log
