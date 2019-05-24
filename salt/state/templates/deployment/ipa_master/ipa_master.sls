{#  this should be ipa_master - IPA does not have masters, just equal replicas #}
{#  however we are using the term master for an 'initial' server deployment #}

{#- save the deployment args for reuse when including ipa_common #}
{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set action          = args.action if 'action' in args else 'all' %}
{%- set deployment_type = args.deployment_type %}
{%- set pwfile          = '/root/.ipa-passwords-' ~ deployment_name %}

{%- if action in [ 'all', 'install' ] %}
{#-     install required packages #}
{%-     set args = { 'package_set_name': 'ipa-server' } %}
{%      include('templates/package/sets.sls') with context %}
{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{{sls}}.{{deployment_name}}.ipa-master-deploy-passwords-generate-random:
    file.managed:
        - name:     {{pwfile}}
        - user:     root
        - group:    root
        - mode:     '600'
        # NOTE the file is only generated if it does not exist because
        # we don't want to overwrite it with different random passwords
        - unless:   test -f "{{pwfile}}"
        - contents: |
            {%- for pw_name in [ 'master', 'admin', 'ds' ] %}
            {{pw_name}}_password="{{config.passwords[pw_name] if 'passwords' in config and pw_name in config.passwords and config.passwords[pw_name] != 'random' else salt['random'].get_str(10)}}"
            {%- endfor %}

{%- set scripts = { 
    '.sh'                 : [ 'lib-ipa' ], 
    '-' ~ deployment_name : [ 'salt-ipa-ticket', 'deploy-ipa-server', 'ipa-postinstall' ],
    ''                    : [ 'host-add', 'host-rm', 'update-hosts', 'reset-user-passwd' ]
    } %}
{%- for script_suffix, script_names in scripts.iteritems() %}
{%-     for script_prefix in script_names %}

{{sls}}.{{deployment_name}}.ipa-master-deploy-{{script_prefix}}:
    file.managed:
        - name:     /usr/local/sbin/{{script_prefix}}{{script_suffix}}
        - source:   salt://{{slspath}}/scripts/{{script_prefix}}.sh.jinja
        - user:     root
        - group:    root
        - mode:     '0700'
        - template: jinja
        - context:
            deployment_name:   '{{deployment_name}}'
            pwfile:            '{{pwfile}}'
            config:            {{config|json}}
            enrol:             'demo'

{%-     endfor %}
{%- endfor %}

{{sls}}.{{deployment_name}}.ipa-master-deploy-salt-integration-ticket-cronjob:
    cron.present:
        - identifier: SALT-IPA-TICKET-RENEWAL
        - user:       root
        - special:    '@daily'
        - name:       /usr/local/sbin/salt-ipa-ticket-{{deployment_name}}

{%-     set args = deployment_args %}
{%      include('templates/deployment/ipa_common/ipa_common.sls') with context %}

{#- # configure action #}
{%- endif %}


{%- if action in [ 'all', 'activate' ] %}

{%-     set activated = 'activated' in deployment and deployment.activated %}

{%-     if activated %}

{{sls}}.{{deployment_name}}.deploy:
    cmd.run:
        - name:     /usr/local/sbin/deploy-ipa-server-{{deployment_name}}
        - unless:   test -f /etc/ipa/ca.crt
        - creates:  /var/log/ipaserver-install.log

{%-         set dependent_states = [] %}
{%-         if 'bind_ips' in config and config.bind_ips %}

{%-             for service_name, listen_ip in config.bind_ips.iteritems() %}
{%-                 if service_name == 'httpd' %}
{%-                     set http_conf  = '/etc/httpd/conf/httpd.conf' %}
{%-                     set nss_conf = '/etc/httpd/conf.d/nss.conf' %}
{%-                     set ssl_conf = '/etc/httpd/conf.d/ssl.conf' %}

{%- do dependent_states.append(['cmd', 'patch-http-conf']) %}
{{sls}}.{{deployment_name}}.patch-http-conf:
    cmd.run:
        - name:     sed -r -i -e 's/^Listen[[:space:]].*:80/Listen {{listen_ip}}:80/' '{{http_conf}}'
        - unless:   grep '^Listen {{listen_ip}}:80' '{{http_conf}}'
        - onlyif:   test -f /etc/ipa/ca.crt

{%- do dependent_states.append(['pkg', 'mod-ssl-conflicts']) %}
{{sls}}.{{deployment_name}}.mod-ssl-conflicts:
    pkg.removed:
        - name: mod_ssl

{#- do dependent_states.append(['cmd', 'patch-http-conf']) #}
{#
 #{{sls}}.{{deployment_name}}.patch-ssl-conf:
 #    cmd.run:
 #        - name:     sed -i -e 's/^Listen 443/Listen {{listen_ip}}:443/' '{{ssl_conf}}'
 #        - unless:   grep '^Listen {{listen_ip}}' '{{ssl_conf}}'
 #        - onlyif:   test -f /etc/ipa/ca.crt
 #}

{%- do dependent_states.append(['cmd', 'patch-nss-conf']) %}
{{sls}}.{{deployment_name}}.patch-nss-conf:
    cmd.run:
        - name:     sed -i -e 's/^Listen 443/Listen {{listen_ip}}:443/' '{{nss_conf}}'
        - unless:   grep '^Listen {{listen_ip}}' '{{nss_conf}}'
        - onlyif:   test -f /etc/ipa/ca.crt

{%-                 elif service_name == 'named' %}
{%-                     set named_conf  = '/etc/named.conf' %}

{%- do dependent_states.append(['cmd', 'patch-named-conf']) %}
{{sls}}.{{deployment_name}}.patch-named-conf:
    cmd.run:
        - name:     sed -r -i '/listen-on-v6/ s/^([[:space:]]*).*/\1listen-on { {{listen_ip}}; 127.0.0.1; }; listen-on-v6 {none;};/' '{{named_conf}}'
        - unless:   egrep 'listen-on [{] {{listen_ip}}' '{{named_conf}}'
        - onlyif:   test -f /etc/ipa/ca.crt

{%-                 endif %}
{%-             endfor %}
{%-         endif %}

{#- # IPA is a bit different from other services in that it uses ipactl to start/stop #}
{#- # and in addition here, if we modified the files above, we want to do a full restart #}

{%-         set running = salt['cmd.run'](['bash','-c','ipactl status 2> /dev/null | cut -d: -f2- | sort | uniq']).splitlines() %}

{{sls}}.{{deployment_name}}.running-status:
    noop.notice:
        - text: |
            {{running|json}}

{%-         set is_running     = 'RUNNING' in running %}
{%-         set is_stopped     = 'STOPPED' in running %}
{%-         set is_partially_running = is_stopped and is_running %}

{%-         if is_partially_running or is_stopped %}

{#- Perform an unconditional restart because some part of the service was not running #}
{{sls}}.{{deployment_name}}.reactivate.unconditional:
    cmd.run:
        - name:     ipactl restart

{%-         elif dependent_states %}

{#- Perform a conditional restart, dependent on whether the configs above changed #}
{{sls}}.{{deployment_name}}.reactivate.conditional:
    cmd.run:
        - name:     ipactl restart
        - onchanges:
            {%- for dependency in dependent_states %}
            - {{dependency[0]}}: {{sls}}.{{deployment_name}}.{{dependency[1]}}
            {%- endfor %}

{%-         endif %}

{%-     else %}

{{sls}}.{{deployment_name}}.deactivate-ipa-server:
    cmd.run:
        - name:     ipactl stop
        - onlyif:   ipactl status | grep RUNNING

{%-     endif %}

{%- endif %}
