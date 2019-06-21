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
        - name:       /usr/local/sbin/salt-ipa-ticket-{{deployment_name}} --renew

{%-     set args = deployment_args %}
{%      include('templates/deployment/ipa_common/ipa_common.sls') with context %}

{#- # configure action #}
{%- endif %}


{%- if action in [ 'all', 'activate' ] %}

{%-     set activated = 'activated' in deployment and deployment.activated %}

{%-     if activated %}

{%-         set dependent_states = [] %}
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

{{sls}}.{{deployment_name}}.deploy:
    cmd.run:
        - name:     /usr/local/sbin/deploy-ipa-server-{{deployment_name}}
        - unless:   test -f /var/log/ipaserver-install.log && ! test -f /var/log/ipaserver-install.FAILED


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
