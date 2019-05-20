{#- save the deployment args for reuse when including ipa_common #}
{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}

{#  this should be ipa_replica - IPA does not have masters, just equal replicas #}
{#  however we are using the term master for an 'initial' server deployment #}
{#  and replica for another server which is joined with an existing master #}

{%- set deployment_type = args.deployment_type %}

{#- install required packages #}
{%- set args = { 'package-set': 'ipa-server' } %}
{%  include('templates/package/sets.sls') with context %}

{%- set replica_key_file = '/root/ipa-replica-'~deployment_name~'.gpg' %}

#ipa-replica-deploy-{{deployment_name}}-prepare-joining-key:
#    file.managed:
#        - name:     {{replica_key_file}}
#        - user:     root
#        - group:    root
#        - mode:     '600'
#        - unless:   test -f "{{replica_key_file}}"
#        - contents: |
#            TODO - this data is obtained from the master

ipa-replica-install-script-{{deployment_name}}:
    file.managed:
        - name:         /usr/local/sbin/ipa-replica-deploy-{{deployment_name}}
        - source:       salt://{{slspath}}/deploy-ipa-replica.sh.jinja
        - user:         root
        - group:        root
        - mode:         '0755'
        - template:     jinja
        - context:
            name:             {{deployment_name}}
            replica_key_file: {{replica_key_file}}
            config:           {{config|json}}
        
ipa-replica-join-{{deployment_name}}:
    cmd.run:
        - name:    /usr/local/sbin/ipa-replica-deploy-{{deployment_name}}
        # TODO - check the log file names
        - unless:  test -f /var/log/ipaserver-install.log
        - creates: /var/log/ipaserver-install.log

{%- set args = deployment_args %}
{%  include('templates/deployment/ipa_common/ipa_common.sls') with context %}
