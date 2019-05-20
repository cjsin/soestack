{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set deployment_type = args.deployment_type %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set prefix          = 'pxeboot-server-deployment-' ~ deployment_name %}

{%- set action = args.action if 'action' in args else 'all' %}

{%- if action in [ 'all', 'install' ] %}

simple-http-requirements:
    pkg.installed:
        - pkgs:
            - python37
        - unless: rpm -q python34 || rpm -q python37

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

simple-http-script-{{deployment_name}}:
    file.managed:
        - name:  /usr/local/sbin/simple-http-{{deployment_name}}
        - user:  root
        - group: root
        - mode:  '0755'
        - contents: |
            #!/bin/bash
            port="{{config.port}}"
            dir="{{config.path}}"
            if [[ -d "${dir}" ]]
            then
                cd "${dir}"
                exec python3 -m http.server "${port}"
            fi

simple-http-service-{{deployment_name}}:
    file.managed:
        - name: /etc/systemd/system/simple-http-{{deployment_name}}.service
        - user: root
        - group: root
        - mode:  '0644'
        - contents: |
            [Unit]
            Description=Simple http server ({{deployment_name}})
            After=NetworkManager-wait-online.service network.target

            [Service]
            ExecStart=/usr/local/sbin/simple-http-{{deployment_name}}
            Type=simple
            User=nobody
            Group=nobody
            UMask=0007

            [Install]
            WantedBy=multi-user.target

{%- endif %}


{%- if action in [ 'all', 'activate' ] %}

simple-http-service-enabled-{{deployment_name}}:
    service.running:
        - name:   simple-http-{{deployment_name}}
        - enable: True

{%- endif %}
