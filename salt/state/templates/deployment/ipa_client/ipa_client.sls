{#- save the deployment args for reuse when including ipa_common #}
{%- set prefix, suffix  = salt.uuid.ids() %}
{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config %}

{#- install required packages #}
{%- with args = { 'package_set_name': 'ipa-client' } %}
{%      include('templates/package/sets.sls') with context %}
{%- endwith %}

{{sls}}.{{prefix}}otp-grain-{{deployment_name}}{{suffix}}:
    grains.present:
        - name:         'ipa'
        - force:        True
        - value: 
            realm:      "{{config.realm}}"
            server:     "{{config.server}}"
            domain:     "{{config.domain}}"
            site:       "{{config.site}}"
            config:     demo

{{sls}}.{{prefix}}ipa-client-install-script-{{deployment_name}}{{suffix}}:
    file.managed:
        - name:         /usr/local/sbin/ipa-client-deploy-{{deployment_name}}
        - source:       salt://{{slspath}}/scripts/deploy-ipa-client.sh.jinja
        - user:         root
        - group:        root
        - mode:         '0755'
        - template:     jinja
        - context:
            name:       {{deployment_name}}
            deployment: {{config|json}}
            DEBUG:      ''
            enrol:      demo
        
{{sls}}.{{prefix}}ipa-client-deploy-{{deployment_name}}{{suffix}}:
    cmd.run:
        - name:         /usr/local/sbin/ipa-client-deploy-{{deployment_name}}
        - unless:       test -f /var/log/ipaclient-install.log
        - creates:      /var/log/ipaclient-install.log


{%- with args = deployment_args %}
{%      include('templates/deployment/ipa_common/ipa_common.sls') with context %}
{%- endwith %}
