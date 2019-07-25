{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    node-exporter:
        deploy_type: node_exporter_baremetal

        activated:       True
        activated_where: {{sls}}

        activate:
            firewall:
                basic:
                    metrics:
                        accept:
                            tcp:
                                http: 9100

        config:
            port:    9100
            storage: /d/local/node_exporter
            textfile_directory: /d/local/node_exporter/textfile_collector 
            options:
                - --collector.textfile.directory /d/local/node_exporter/textfile_collector 
                - --collector.filesystem.ignored-mount-points=^(/sys$|/proc$|/dev$|/var/lib/docker/.*|/run.*|/sys/fs/.*) 
                - --collector.filesystem.ignored-fs-types=^(sysfs|procfs|autofs|overlay|nsfs|securityfs|pstore)$ 

        filesystem:
            defaults:
                user:     node_exporter
                group:    node_exporter
                mode:     '0755'
                file_mode: '0644'
                dir_mode:  '0755'
                makedirs: True

            dirs:
                /d/local/node_exporter:
                /d/local/node_exporter/text-collector:

            files:
                /etc/sysconfig/node_exporter:
                    template:        node-exporter-sysconfig
                    config_pillar:   :config
                /etc/systemd/system/node_exporter.service:
                    template:        node-exporter-service
                    config_pillar:   :config
            templates:
                node_exporter-service: |
                    {%raw%}
                    [Unit]
                    Description=Node Exporter

                    [Service]
                    User=node_exporter
                    Environment=OPTIONS=
                    EnvironmentFile=-/etc/sysconfig/node_exporter
                    ExecStart=/opt/node_exporter/node_exporter $OPTIONS

                    [Install]
                    WantedBy=multi-user.target
                    {%endraw%}
                node_exporter-sysconfig: |
                    {%raw%}
                    {%- set options = config.options if 'options' in config and config.options else [] %}
                    OPTIONS={% for opt in options %}{{opt}} {% endfor %}
                    {%endraw%}

