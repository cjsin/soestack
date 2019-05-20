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

.ipa-master-deploy-{{deployment_name}}-passwords-generate-random:
    file.managed:
        - name:     {{pwfile}}
        - user:     root
        - group:    root
        - mode:     '600'
        - unless:   test -f "{{pwfile}}"
        - contents: |
            master_password="master123" # "{{salt['random'].get_str(10)}}"
            admin_password="admin123" # "{{salt['random'].get_str(10)}}"
            ds_password="{{salt['random'].get_str(20)}}"

{%- set scripts = { 
    '.sh' : ['lib-ipa'], 
    '-' ~ deployment_name : [ 'salt-ipa-ticket', 'ipa-server-deploy' ],
    '': [ 'host-add', 'host-rm', 'update-hosts', 'ipa-postinstall', 'reset-user-passwd' ]
    } %}
{%- for script_suffix, script_names in scripts.iteritems() %}
{%-     for script_prefix in script_names %}

.ipa-master-deploy-{{script_prefix}}-{{deployment_name}}:
    file.managed:
        - name:     /usr/local/sbin/{{script_prefix}}{{script_suffix}}
        - source:   salt://{{slspath}}/scripts/{{script_prefix}}.sh.jinja
        - user:     root
        - group:    root
        - mode:     '0700'
        - template: jinja
        - context:
            name:   {{deployment_name}}
            pwfile: {{pwfile}}
            config: {{config|json}}
            enrol:  demo

{%-     endfor %}
{%- endfor %}

.ipa-master-deploy-salt-integration-ticket-cronjob:
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

.deploy-{{deployment_name}}:
    cmd.run:
        - name:     /usr/local/sbin/ipa-server-deploy-{{deployment_name}}
        - unless:   test -f /etc/ipa/ca.crt
        - creates:  /var/log/ipaserver-install.log

{%-         if 'bind_ips' in config and config.bind_ips %}
{%-             for service_name, listen_ip in config.bind_ips.iteritems() %}
{%-                 if service_name == 'httpd' %}
{%-                     set http_conf  = '/etc/httpd/conf/httpd.conf' %}
{%-                     set nss_conf = '/etc/httpd/conf.d/nss.conf' %}
{%-                     set ssl_conf = '/etc/httpd/conf.d/ssl.conf' %}

.patch-http-conf:
    cmd.run:
        - name:     sed  -i -e 's/^Listen 80/Listen {{listen_ip}}:80/' '{{http_conf}}'
        - unless:   grep '^Listen {{listen_ip}}' '{{http_conf}}'
        - onlyif:   test -f /etc/ipa/ca.crt

.mod-ssl-conflicts:
    pkg.uninstalled:
        - name: mod_ssl

#.patch-ssl-conf:
#    cmd.run:
#        - name:     sed -i -e 's/^Listen 443/Listen {{listen_ip}}:443/' '{{ssl_conf}}'
#        - unless:   grep '^Listen {{listen_ip}}' '{{ssl_conf}}'
#        - onlyif:   test -f /etc/ipa/ca.crt

.patch-nss-conf:
    cmd.run:
        - name:     sed -i -e 's/^Listen 443/Listen {{listen_ip}}:443/' '{{nss_conf}}'
        - unless:   grep '^Listen {{listen_ip}}' '{{nss_conf}}'
        - onlyif:   test -f /etc/ipa/ca.crt

{%-                 elif service_name == 'named' %}
{%-                     set named_conf  = '/etc/named.conf' %}

# Note, we also disable IPv6 DNS here
.patch-named-conf:
    cmd.run:
        - name:     sed -r -i '/listen-on-v6/ s/^([[:space:]]*).*/\1listen-on { {{listen_ip}}; 127.0.0.1; }; listen-on-v6 {none;};/' '{{named_conf}}'
        - unless:   egrep 'listen-on [{] {{listen_ip}}' '{{named_conf}}'
        - onlyif:   test -f /etc/ipa/ca.crt

{%-                 endif %}
{%-             endfor %}
{%-         endif %}

activate-ipa-server:
    cmd.run:
        - name:     ipactl start
        - onlyif:   ipactl status | grep STOPPED 

{%-     else %}

deactivate-ipa-server:
    cmd.run:
        - name:     ipactl stop
        - onlyif:   ipactl status | grep RUNNING

{%-     endif %}

{%- endif %}
