{{ salt.loadtracker.load_pillar(sls) }}

deployments:

    ss-elk:
        deploy_type: elasticsearch_container
        roles:
            - elasticsearch-node
        activated: False
        activated_where: {{sls}}
        activate:
            firewall:
                basic:
                    elasticsearch-ports:
                        ip: '!!demo.ips.elasticsearch'
                        accept:
                            tcp:
                                http:    9200
                                elastic: 9300
        container:
            description: Elasticsearch cluster
            volumes:
                - -v /etc/elasticsearch/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
                - -v /etc/elasticsearch/jvm.options:/usr/share/elasticsearch/config/jvm.options
                - -v /d/local/data/elasticsearch:/usr/share/elasticsearch/data
            ports:
                - -p 192.168.121.109:9200:9200
                - -p 192.168.121.109:9300:9300
            image:   nexus:7083/elasticsearch/elasticsearch:6.4.0
            env: 
                - -e XPACK_REPORTING_ENABLED=false
                - -e XPACK_SECURITY_ENABLED=false
            mounts:
                /etc/elasticsearch/elasticsearch.yml: file
                /etc/elasticsearch/jvm.options: file
                /d/local/data/elasticsearch: dir
            storage:
                - /d/local/data/elasticsearch
            user: 1000
            group: 1000

        config:
            cluster_name: testdev_cluster
            listen_address: 0.0.0.0
            # set to 1 to allow single node clusters
            minimum_master_nodes: 1
            jvm:
                initial_vm: 500m
                max_vm:     500m


        filesystem:
            templates:
                elasticsearch-yml: salt://templates/deployment/elasticsearch_container/elasticsearch.yml.jinja
                elasticsearch-jvm-options: salt://templates/deployment/elasticsearch_container/jvm-options.jinja

            defaults:
                user: 1000
                group: 1000

            dirs:
                /etc/elasticsearch:

            files:
                /etc/sysctl.d/99-elasticsearch.conf:
                    contents:        'vm.max_map_count=262144'
                /etc/elasticsearch/elasticsearch.yml:
                    config_pillar:   ':config'
                    template:        elasticsearch-yml
                /etc/elasticsearch/jvm.options:
                    config_pillar:   ':config'
                    template:        elasticsearch-jvm-options
