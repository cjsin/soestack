{#  this should be ipa_master - IPA does not have masters, just equal replicas #}
{#  however we are using the term master for an 'initial' server deployment #}

{#- save the deployment args for reuse when including ipa_common #}
{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set action          = args.action if 'action' in args else 'all' %}
{%- set deployment_type = args.deployment_type %}


{#- first do common IPA stuff #}

{%- set args = deployment_args %}
{%  include('templates/deployment/ipa_common/ipa_common.sls') with context %}

{%- if action in [ 'all', 'install' ] %}
{#-     install required packages #}
{%-     set args = { 'package_set_name': 'ipa-server' } %}
{%      include('templates/package/sets.sls') with context %}
{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{#- scripts that are only for ipa servers #}
{%- set scripts = { 
    '' : [ 'salt-ipa-ticket', 'ipa-postinstall', 'host-add', 'host-rm', 'user-create', 'update-hosts', 'reset-user-passwd' ]
    } %}
{%- for script_suffix, script_names in scripts.iteritems() %}
{%-     for script_prefix in script_names %}

{{sls}}.{{deployment_name}}.ipa-server-script-{{script_prefix}}:
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

{%-     endfor %}
{%- endfor %}

{#- cron job for salt ticket renewal #}
{{sls}}.{{deployment_name}}.ipa-master-deploy-salt-integration-ticket-cronjob:
    cron.present:
        - identifier: SALT-IPA-TICKET-RENEWAL
        - user:       root
        - special:    '@daily'
        - name:       /usr/local/sbin/salt-ipa-ticket --renew

{#- # configure action #}
{%- endif %}


{%- if action in [ 'all', 'activate' ] %}

{%-     set activated = 'activated' in deployment and deployment.activated %}

{%-     if activated %}

{%-         set dependent_states = [] %}
{#-         note that replicas will have to specify their own bind_ips #}
{%-         if 'bind_ips' in config and config.bind_ips %}

{%-             for service_name, listen_ip in config.bind_ips.iteritems() %}
{%-                 if service_name == 'httpd' %}
{%-                     set http_conf  = '/etc/httpd/conf/httpd.conf' %}
{%-                     set nss_conf = '/etc/httpd/conf.d/nss.conf' %}
{%-                     set ssl_conf = '/etc/httpd/conf.d/ssl.conf' %}

{%- do dependent_states.append(['file', 'patch-http-conf']) %}

{{sls}}.{{deployment_name}}.patch-http-conf:
    file.replace:
        - name:     '{{http_conf}}'
        - pattern:  '^Listen([\t ].*|)$'
        - repl:     'Listen {{listen_ip}}:80'
        - onlyif:   test -f '{{http_conf}}'

{%- do dependent_states.append(['pkg', 'mod-ssl-conflicts']) %}
{{sls}}.{{deployment_name}}.mod-ssl-conflicts:
    pkg.removed:
        - name: mod_ssl

{%- do dependent_states.append(['file', 'delete-ssl-conf']) %}
{{sls}}.{{deployment_name}}.delete-ssl-conf:
    file.absent:
        - name: /etc/httpd/conf.d/ssl.conf


{%- do dependent_states.append(['file', 'patch-nss-conf']) %}
{{sls}}.{{deployment_name}}.patch-nss-conf:
    file.replace:
        - name:     '{{nss_conf}}'
        - pattern:  '^Listen([\t ].*|)$'
        - repl:     'Listen {{listen_ip}}:443'
        - onlyif:   test -f '{{nss_conf}}'

{%-                 elif service_name == 'named' %}
{%-                     set named_conf  = '/etc/named.conf' %}

{%- do dependent_states.append(['file', 'patch-named-conf']) %}
{{sls}}.{{deployment_name}}.patch-named-conf:
    file.replace:
        - name:     '{{named_conf}}'
        - pattern:  'listen-on-v6.*;'
        - repl:     'listen-on-v6 {none;};'
        - onlyif:   test -f '{{named_conf}}'

{%-                 endif %}
{%-             endfor %}
{%-         endif %}

# Now testing performing the IPA server deploy *after* performing the above modifications 
#   because the initial ipa-server-install fails to start httpd, with bind errors
# To that end, we attempt to restart httpd also, prior to the IPA install

{#- Perform a conditional restart, dependent on whether the configs above changed #}
{{sls}}.{{deployment_name}}.restart-http.conditional:
    cmd.run:
        - name:     systemctl restart httpd
        - onchanges:
            {%- for dependency in dependent_states %}
            - {{dependency[0]}}: {{sls}}.{{deployment_name}}.{{dependency[1]}}
            {%- endfor %}

{%-     endif %}

{%- endif %}
