{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ss-logstash-sys:
        deploy_type:     logstash_baremetal
        activated:       False
        activated_where: {{sls}}
        hosts:
            - '.*'

        activate:
            services:
                enabled:
                    - ss-logstash-sys

        config:
            listen_address:          '{{grains.fqdn_ip4[0]}}'
            server_host:             "0"
            elasticsearch_url:       http://192.168.121.109:9200
            xpack_elasticsearch_url: http://192.168.121.109:9200
            # Config_subdir should match the location (under /etc/logstash) of the config files
            # that are generated below
            config_subdir:           sys

        account:
            user: logstash
            extra_groups: 
                - adm

        filesystem:
            templates:
                logstash-sys-yml: |
                    {%raw%}
                    http.host: "{{config.listen_address or '0.0.0.0'}}"
                    xpack.monitoring.elasticsearch.url: {{config.xpack_elasticsearch_url or 'http://elasticsearch:9200'}}
                    {%endraw%}
                logstash-sys-conf: |
                    {%raw%}
                    input {
                        file {
                            path => "/var/log/yum.log"
                        }
                        file {
                            path => "/var/log/cron.log"
                            type => "syslog"
                        }
                        file {
                            path => "/var/log/messages"
                            type => "syslog"
                        }
                    }
                    output {
                        elasticsearch {
                            hosts => ["{{config.elasticsearch_url}}"]
                            index => "system-%{+YYYY.MM.dd}"
                        }
                    }
                    {%endraw%}
                logstash-sys-pipelines-yml: |
                    {%raw%}
                    - pipeline.id: main
                        path.config: "/etc/logstash/sys/pipeline"
                    {%endraw%}


            dirs:
                /etc/logstash:
                    user:            root
                    group:           root
                    mode:            '0755'
                /etc/logstash/sys:
                    user:            logstash
                    group:           logstash
                /etc/logstash/sys/pipeline:
                    user:            logstash
                    group:           logstash

            files:
                /etc/logstash/sys/logstash.yml:
                    config_pillar:   ':config'
                    template:        logstash-sys-yml
                    user:            logstash
                    group:           logstash
                /etc/logstash/sys/pipeline/logstash.conf:
                    config_pillar:   ':config'
                    template:        logstash-sys-conf
                    user:            logstash
                    group:           logstash
                /etc/logstash/sys/pipelines.yml:
                    config_pillar:   ':config'
                    template:        logstash-sys-pipelines-yml
                    user:            logstash
                    group:           logstash

