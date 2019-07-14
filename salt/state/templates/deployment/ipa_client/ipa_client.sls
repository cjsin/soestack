{#- save the deployment args for reuse when including ipa_common #}
{%- set prefix, suffix  = salt.uuids.ids() %}
{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config %}
{%- set action          = args.action if 'action' in args else 'all' %}

{%- with args = deployment_args %}
{%      include('templates/deployment/ipa_common/ipa_common.sls') with context %}
{%- endwith %}

{%- if action in [ 'all', 'install' ] %}

{#-     install required packages #}
{%-     with args = { 'package_set_name': 'ipa-client' } %}
{%      include('templates/package/sets.sls') with context %}
{%-     endwith %}

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{{sls}}.{{prefix}}site-grain-{{deployment_name}}{{suffix}}:
    grains.present:
        - name:         'ipa'
        - force:        True
        - value: 
            site:       "{{config.site}}"

{{sls}}.{{prefix}}ipa-client-install-script-{{deployment_name}}{{suffix}}:
    file.managed:
        - name:         /usr/local/bin/deploy-ipa-client
        - source:       salt://{{slspath}}/scripts/deploy-ipa-client.sh.jinja
        - user:         root
        - group:        root
        - mode:         '0755'
        - template:     jinja
        - context:
            name:       {{deployment_name}}
            deployment: {{config|json}}
            DEBUG:      ''

{{sls}}.{{prefix}}ipa-client-deploy-{{deployment_name}}{{suffix}}:
    cmd.run:
        - name:         /usr/local/bin/deploy-ipa-client
        - unless:       test -f /var/log/ipaclient-install.log
        - creates:      /var/log/ipaclient-install.log

{%- endif %}
