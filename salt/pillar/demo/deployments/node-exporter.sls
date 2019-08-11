{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ss-node-exporter:
        deploy_type:    node_exporter_baremetal
        host:           '.*'
        activated:       True
        activated_where: {{sls}}

        install:
                
            installed:
                package-sets:
                    - node-exporter-custom-build

        activate:
            services:
                enabled:
                    - ss-node-exporter
            firewall:
                basic:
                    metrics:
                        accept:
                            tcp:
                                http: 9100

        config:
            port:    9100
            storage: /d/local/data/ss-node-exporter
            textfile_directory: /d/local/data/ss-node-exporter/text-collector 
            options:
                - --collector.textfile.directory /d/local/data/ss-node-exporter/text-collector 
                - --collector.filesystem.ignored-mount-points=^(/sys$|/proc$|/dev$|/var/lib/docker/.*|/run.*|/sys/fs/.*) 
                - --collector.filesystem.ignored-fs-types=^(sysfs|procfs|autofs|overlay|nsfs|securityfs|pstore)$ 

        filesystem:
            defaults:
                user:      node_exporter
                group:     node_exporter
                file_mode: '0644'
                dir_mode:  '0755'
                makedirs:  True

            dirs:
                /d/local/data/ss-node-exporter:
                /d/local/data/ss-node-exporter/text-collector:

            files:
                /etc/sysconfig/ss-node-exporter:
                    user:            root
                    group:           root
                    template:        node-exporter-sysconfig
                    config_pillar:   :config
                /etc/systemd/system/ss-node-exporter.service:
                    user:            root
                    group:           root
                    template:        node-exporter-service
                    config_pillar:   :config
            templates:
                node-exporter-service: |
                    {%raw%}
                    [Unit]
                    Description=Node Exporter

                    [Service]
                    User=node_exporter
                    Environment=OPTIONS=
                    EnvironmentFile=-/etc/sysconfig/ss-node-exporter
                    ExecStart=/opt/node_exporter/node_exporter $OPTIONS

                    [Install]
                    WantedBy=multi-user.target
                    {%endraw%}
                node-exporter-sysconfig: |
                    {%raw%}
                    {%- set options = config.options if 'options' in config and config.options else [] %}
                    OPTIONS={% for opt in options %}{{opt}} {% endfor %}
                    {%endraw%}

