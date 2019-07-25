{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set deployment_type = args.deployment_type %}
{%- set config          = deployment.config if 'config' in deployment else {} %}

{%- set action = args.action if 'action' in args else 'all' %}

{%- if action in [ 'all', 'install' ] %}

{{sls}}.{{deployment_name}}.simple-http-requirements:
    pkg.installed:
        - pkgs:
            - python37
        - unless: rpm -q python34 || rpm -q python37

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{{sls}}.{{deployment_name}}.sysconfig:
    file.managed:
        - name: /etc/sysconfig/{{deployment_name}}
        - user:  root
        - group: root
        - mode:  '0755'
        - contents: |
            bind_ip="{{config.bind_ip}}"
            port="{{config.port}}"
            dir="{{config.path}}"

{{sls}}.{{deployment_name}}.service-script:
    file.managed:
        - name:  /usr/local/bin/{{deployment_name}}
        - user:  root
        - group: root
        - mode:  '0755'
        - contents: |
            #!/bin/bash
            . /etc/sysconfig/{{deployment_name}}

            cmd=("python3" "-m" "http.server" "${port}")
            [[ -n "${bind_ip}" ]] && cmd+=("--bind" "${bind_ip}")

            if [[ ! -d "${dir}" ]]
            then
                echo "ERROR: No such dir: ${dir}" 1>&2
                exit 1
            fi
            
            if ! cd "${dir}"
            then
                echo "ERROR: No permissions: ${dir}" 1>&2
                exit 1
            fi 

            echo "${cmd[@]}" 1>&2
            "${cmd[@]}"

{{sls}}.{{deployment_name}}.service-unit:
    file.managed:
        - name:     /etc/systemd/system/{{deployment_name}}.service
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            [Unit]
            Description=Simple http server ({{deployment_name}})
            After=NetworkManager-wait-online.service network.target

            [Service]
            ExecStart=/usr/local/bin/{{deployment_name}}
            Type=simple
            User={{config.user if 'user' in config else 'nobody'}}
            Group={{config.user if 'user' in config else 'nobody'}}
            UMask=0007

            [Install]
            WantedBy=multi-user.target

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}

{{sls}}.{{deployment_name}}.service-enabled:
    service.running:
        - name:   {{deployment_name}}
        - enable: True

{%- endif %}
