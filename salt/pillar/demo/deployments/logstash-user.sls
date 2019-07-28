{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ss-logstash-user:
        deploy_type: logstash_container
        roles:
            - processor-node
        activated: False
        activated_where: {{sls}}
        activate:
            firewall:
                basic:
                    logstash-frontend:
                        ip: '{{grains.fqdn_ip4[0]}}'
                        accept:
                            tcp:
                                tcp5044: 5044
                                tcp9600: 9600
                                json:    12345
                                http:    12345
            services:
                enabled:
                    - ss-logstash-user

        container:
            description: logstash service
            volumes:
                - -v /etc/logstash/user/logstash.yml:/usr/share/logstash/config/logstash.yml
                - -v /etc/logstash/user/pipelines.yml:/usr/share/logstash/config/pipelines.yml
                - -v /etc/logstash/user/pipeline/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
                - -v /d/local/data/logstash/user:/usr/share/logstash/data
            ports:
                - -p 5044:5044
                - -p 9600:9600
                - -p 12345:12345
                - -p 12346:12346
            image:   nexus:7083/logstash/logstash:6.4.0
            options: 
            mounts:
#                    /d/local/data/logstash/user: dir
#                    /etc/logstash/user/pipeline: dir
#                    /etc/logstash/user/logstash.yml: file
#                    /etc/logstash/user/pipelines.yml: file
#                    /etc/logstash/user/pipeline/logstash.conf: file
            storage:
                - /d/local/data/logstash/user/
            user: 1000
            group: 1000

        config:
            listen_address:          "0.0.0.0"
            server_host:             "0"
            elasticsearch_url:       http://192.168.121.109:9200
            xpack_elasticsearch_url: http://192.168.121.109:9200
            json_port:               12345
            http_port:               12346
            # Config_subdir should match the location (under /etc/logstash) of the config files
            # that are generated below
            config_subdir:           user

        filesystem:
            templates:
                logstash-user-yml: |
                    {%raw%}
                    http.host: "{{config.listen_address or '0.0.0.0'}}"
                    xpack.monitoring.elasticsearch.url: {{config.xpack_elasticsearch_url or 'http://elasticsearch:9200'}}
                    {%endraw%}
                logstash-user-conf: |
                    {%raw%}
                    input {
                        tcp {
                            port  => {{config.json_port}}
                            codec => json
                        }
                        http {
                            port  => {{config.http_port}}
                        }
                    }
                    output {
                        elasticsearch {
                            hosts => ["{{config.elasticsearch_url}}"]
                            index => "dev-%{[@metadata][version]}-%{+YYYY.MM.dd}"
                        }
                        stdout {
                            codec => json
                        }
                    }
                    {%endraw%}
                logstash-user-pipelines-yml: |
                    {%raw%}
                    - pipeline.id: main
                        path.config: "/usr/share/logstash/pipeline"
                    {%endraw%}


            dirs:
                /etc/logstash:
                    user:            root
                    group:           root
                    mode:            '0755'
                /etc/logstash/user:
                    user:            1000
                    group:           1000
                /etc/logstash/user/pipeline:
                    user:            1000
                    group:           1000

            files:
                /etc/logstash/user/logstash.yml:
                    config_pillar:   ':config'
                    template:        logstash-user-yml
                    user:            1000
                    group:           1000
                /etc/logstash/user/pipeline/logstash.conf:
                    config_pillar:   ':config'
                    template:        logstash-user-conf
                    user:            1000
                    group:           1000
                /etc/logstash/user/pipelines.yml:
                    config_pillar:   ':config'
                    template:        logstash-user-pipelines-yml
                    user:            1000
                    group:           1000

