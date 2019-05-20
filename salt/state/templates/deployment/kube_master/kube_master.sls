{%- set deployment_name = args.deployment_name %}
{%- set deployment_type = args.deployment_type %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config %}
{%- set action = args.action if 'action' in args else 'all' %}

# need net.bridge.bridge* sysctls
# need to disable swap first too

{%- if action in [ 'all', 'install'] %}

{%-     if 'images' in config and config.images %}
{%-         with args = { 'images' : config.images } %}
{%              include('templates/docker/images.sls') with context %}
{%-         endwith %}
{%-     endif %}

{%- endif %}

{%- if action in [ 'all', 'configure'] %}

.disable-swap:
    cmd.run:
        - name: |
            swapoff -a
            sed -i '/^[^#].*[[:space:]]swap[[:space:]]/ s/^/#/' /etc/fstab 
        - onlyif: egrep -i '^[^#].*[[:space:]]swap[[:space:]]' /etc/fstab 

.cluster-init-script:
    file.managed:
        - name: /usr/local/sbin/kube-cluster-init-{{deployment_name}}
        - user: root
        - group: root
        - mode:  '0755'
        - source: salt://templates/deployment/kube_master/kube-cluster-init.sh.jinja
        - template: jinja
        - context:
            config: {{config|json}}

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}

{%-     set activated = 'activated' in deployment and deployment.activated %}

{%-     if activated %}

kube-cluster-init:
    cmd.run:
        - unless: test -f /etc/kubernetes/admin.conf
        - name:   /usr/local/sbin/kube-cluster-init-{{deployment_name}}

{%-     endif %}

kubelet-service:
    service.{{'running' if activated else 'dead'}}:
        - name:   kubelet
        - enable: {{activated}} 

{%- endif %}
