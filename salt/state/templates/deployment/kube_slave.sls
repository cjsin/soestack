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

{{sls}}.cluster-join-script:
    file.managed:
        - name: /usr/local/sbin/kube-cluster-join-{{deployment_name}}
        - user: root
        - group: root
        - mode:  '0755'
        #- source: salt://templates/deployment/kube_master/kube-cluster-join.sh.jinja
        - template: jinja
        - context:
            config: {{config|json}}
        - contents: |
            kubeadm join 192.168.121.110:6443 --token c8zvuy.kng2kjp0hmr431va --discovery-token-ca-cert-hash sha256:4ac2bdc0e91fc0d00bcf94f1cd2a385ff8c7f1b0390d09280c818181f0007ada

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}

{%-     if 'activated' in deployment and deployment.activated %}

{{sls}}.kube-cluster-init:
    cmd.run:
        - unless: test -d /etc/kubernetes/pki
        - name:   /usr/local/sbin/kube-cluster-join-{{deployment_name}}

{%-     endif %}

{%- endif %}
