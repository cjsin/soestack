{{ salt.loadtracker.load_pillar(sls) }}

deployments:

    ss-prometheus:
        deploy_type:     prometheus_container
        activated:       False
        activated_where: {{sls}}

        install:
            nuggets-required:
                - docker-services
        activate:
            nuggets-required:
                - docker-services

            services:
                enabled:
                    - ss-prometheus
                    
            firewall:
                basic:
                    ss-prometheus:
                        ip: 192.168.121.108
                        accept:
                            tcp:
                                http: 9090
        container:
            description:  Prometheus metrics and monitoring
            image:        prom/prometheus:v2.3.2
            volumes: 
                - -v /d/local/data/prometheus:/prometheus
                - -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
            ports:   
                - -p 192.168.121.108:9090:9090
            user:    nfsnobody
            group:   nfsnobody
            options: 
            storage: 
                - /d/local/data/prometheus
            mounts:
                /d/local/data/prometheus: dir
                /etc/prometheus/prometheus.yml: file
        config:
            port:        9090
            global:
                scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
                evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
            node_exporter:
                node_lists_key: node_lists:prometheus

        filesystem:
            templates:
                prometheus-yml: salt://templates/deployment/prometheus_container/prometheus.yml.jinja

            defaults:
                user:    nfsnobody
                group:   nfsnobody

            dirs:
                /etc/prometheus:
                /d/local/data:
                    user: root
                    group: root
                /d/local/data/prometheus:

            files:
                /etc/prometheus/prometheus.yml:
                    config_pillar:   :config
                    template:        prometheus-yml
        