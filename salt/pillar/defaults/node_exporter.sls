deployments:
    node_exporter_baremetal:
        node_exporter:

            activated:       True
            activated_where: {{sls}}

            activate:
                firewall:
                    basic:
                        metrics:
                            accept:
                                tcp:
                                    http: 9100

            filesystem:
                defaults:
                    user:     node_exporter
                    group:    node_exporter
                    mode:     '0755'
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
                    node-exporter-sysconfig: salt://templates/deployment/node_exporter_baremetal/sysconfig.jinja
                    node-exporter-service:   salt://templates/deployment/node_exporter_baremetal/service.jinja

            config:
                port:    9100
                storage: /d/local/node_exporter
                textfile_directory: /d/local/node_exporter/textfile_collector 
                options:
                    - --collector.textfile.directory /d/local/node_exporter/textfile_collector 
                    - --collector.filesystem.ignored-mount-points=^(/sys$|/proc$|/dev$|/var/lib/docker/.*|/run.*|/sys/fs/.*) 
                    - --collector.filesystem.ignored-fs-types=^(sysfs|procfs|autofs|overlay|nsfs|securityfs|pstore)$ 
