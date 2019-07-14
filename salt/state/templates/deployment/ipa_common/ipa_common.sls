{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set deployment_type = args.deployment_type %}
{%- set ipa             = pillar.ipa if 'ipa' in pillar else {} %}
{%- set prefix, suffix  = salt.uuids.ids() %}
{%- set action          = args.action if 'action' in args else 'all' %}

{%- if action in [ 'all', 'configure' ] %}

{{sls}}.{{deployment_name}}.ipa-master-deploy-ipa-tools-{{suffix}}:
    file.managed:
        - name:     /etc/sysconfig/ipa-tools
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            IPA_SERVER="{{ipa.server if 'server' in ipa else ''}}"
            IPA_SERVER_IP="{{ipa.server_ip if 'server_ip' in ipa else ''}}"
            IPA_REALM="{{ipa.realm if 'realm' in ipa else ''}}"
            IPA_BIND_USER="{{ipa.bind_user if 'bind_user' in ipa else ''}}"
            IPA_BASE_DN="{{ipa.base_dn if 'base_dn' in ipa else ''}}"
            IPA_REVERSE_ZONE="{{ipa.reverse_zone if 'reverse_zone' in ipa else ''}}"
            IPA_ZONE="{{ipa.domain if 'domain' in ipa else ''}}"
            IPA_DOMAIN="{{ipa.domain if 'domain' in ipa else ''}}"
            IPA_DEFAULT_SITE="{{ipa.default_site if 'default_site' in ipa else ''}}"
            IPA_SITE="{{ipa.site if 'site' in ipa else ipa.default_site if 'default_site' in ipa else ''}}"


{%-     set scripts = { 
            '.sh'                 : [ 'lib-ipa' ]
        } %}
{%-     for script_suffix, script_names in scripts.iteritems() %}
{%-         for script_prefix in script_names %}

{{sls}}.{{deployment_name}}.ipa-common-script-{{script_prefix}}:
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
{%- endif %}
