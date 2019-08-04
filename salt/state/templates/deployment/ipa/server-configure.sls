{#- configure other services on th ebox to allow it to successfully run IPA #}

{%- set deployment_args = args %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}

{#- build up a list of states which can trigger a httpd restart #}
{%- set dependent_states = [] %}

# Generate a secret which will be used for enrolling clients
{% do salt.secrets.master_check_or_generate('ipa_client_enrol') %}

{%- do dependent_states.append(['pkg', 'mod-ssl-conflicts']) %}
{{sls}}.{{deployment_name}}.mod-ssl-conflicts:
    pkg.removed:
        - name: mod_ssl

{%- do dependent_states.append(['file', 'delete-ssl-conf']) %}
{{sls}}.{{deployment_name}}.delete-ssl-conf:
    file.absent:
        - name: /etc/httpd/conf.d/ssl.conf

{%- do dependent_states.append(['file', 'patch-named-conf']) %}
{{sls}}.{{deployment_name}}.patch-named-conf:
    file.replace:
        - name:     '/etc/named.conf'
        - pattern:  'listen-on-v6.*;'
        - repl:     'listen-on-v6 {none;};'
        - onlyif:   test -f '/etc/named.conf'

{%- if 'bind_ips' in config and config.bind_ips and 'httpd' in config.bind_ips and config.bind_ips.httpd not in ['','unset',None] %}
{%-     set listen_ip = config.bind_ips.httpd %}

{%-     do dependent_states.append(['file', 'patch-http-conf']) %}
{{sls}}.{{deployment_name}}.patch-http-conf:
    file.replace:
        - name:     '/etc/httpd/conf/httpd.conf'
        - pattern:  '^Listen([\t ].*|)$'
        - repl:     'Listen {{listen_ip}}:80'
        - onlyif:   test -f '/etc/httpd/conf/httpd.conf'

{%-     do dependent_states.append(['file', 'patch-nss-conf']) %}
{{sls}}.{{deployment_name}}.patch-nss-conf:
    file.replace:
        - name:     /etc/httpd/conf.d/nss.conf
        - pattern:  '^Listen([\t ].*|)$'
        - repl:     'Listen {{listen_ip}}:443'
        - onlyif:   test -f /etc/httpd/conf.d/nss.conf

{%- else %}
{{sls}}.{{deployment_name}}.missing-configuration:
    noop.warning:
        - text: Cannot configure Bind IPs for IPA {{node_type}} because bind_ips is not specified in the pillar config
{%- endif %}

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

{#- cron job for salt ticket renewal #}
{{sls}}.{{deployment_name}}.salt-ipa-ticket-cronjob:
    cron.present:
        - identifier: SALT-IPA-TICKET-RENEWAL
        - user:       root
        - special:    '@daily'
        - name:       /usr/local/bin/salt-ipa-ticket --renew

.script:
    file.managed:
        - name: /usr/local/sbin/backups/jobs/ipa
        - user: root
        - group: root
        - mode: '0755'
        - contents: |
            #!/bin/bash
            ipa-server-backup-job
