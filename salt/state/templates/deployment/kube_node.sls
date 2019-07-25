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

{{sls}}.disable-swap:
    cmd.run:
        - name: |
            swapoff -a
            sed -i '/^[^#].*[[:space:]]swap[[:space:]]/ s/^/#/' /etc/fstab 
        - onlyif: egrep -i '^[^#].*[[:space:]]swap[[:space:]]' /etc/fstab 

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}

{%-     set activated = 'activated' in deployment and deployment.activated %}

{{sls}}.kubelet-service:
    service.{{'running' if activated else 'dead'}}:
        - name:   kubelet
        - enable: {{activated}} 

{%- endif %}
