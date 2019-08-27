{%- import 'lib/noop.sls' as noop %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set deployment_type = args.deployment_type %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set prefix          = 'pgp-server-deployment-' ~ deployment_name %}
{%- set action = args.action if 'action' in args else 'all' %}

{#- NOTE that these are activated here not in the nugget because #}
{#- this particular service needs to be initialised the first time #}
{%- if action in [ 'all', 'configure' ] %}

{{sls}}.nginx-pgp-port-selinux-policy-te:
    file.managed:
        - name: /root/nginx-pgpkeyserver-port.te
        - user: root
        - group: root
        - contents: |
            module nginx-pgpkeyserver-port 1.0;
            require {
                type httpd_t;
                type pgpkeyserver_port_t;
                class tcp_socket name_bind;
            }
            # The nginx service for sks-web uses the pgp keyserver port also
            allow httpd_t pgpkeyserver_port_t:tcp_socket name_bind;

{{sls}}.nginx-pgp-port-selinux-policy-mod:
    cmd.run:
        - name: checkmodule -M -m -o /root/nginx-pgpkeyserver-port.mod /root/nginx-pgpkeyserver-port.te
        - onchanges:
            - file: {{sls}}.nginx-pgp-port-selinux-policy-te

{{sls}}.nginx-pgp-port-selinux-policy-pp:
    cmd.run:
        - name: semodule_package -o /root/nginx-pgpkeyserver-port.pp -m /root/nginx-pgpkeyserver-port.mod
        - onchanges:
            - cmd: {{sls}}.nginx-pgp-port-selinux-policy-mod

{{sls}}.nginx-pgp-port-selinux-policy-loaded:
    selinux.module:
        - name: nginx-pgpkeyserver-port
        - module_state: 'Enabled' 
        - install: True
        - source: /root/nginx-pgpkeyserver-port.pp


#{{sls}}.{{deployment_type}}.{{deployment_name}}.selinux-ports-{{action}}:
#    selinux.port_policy_present:
#        - name: tcp/11371
#        - sel_type: http_port_t
#        - unless: semanage port -l | egrep ^http_port_t | egrep '

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}
{%-     set activated = 'activated' in deployment and deployment.activated %}
{%-     for svc in [ 'sks-db', 'sks-recon', 'sks-web' ] %}

{{sls}}.pgp_keyserver.{{prefix}}services.{{svc}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{svc}}
        - enable: {{activated}} 

{%-     endfor %}
{%- endif %}


