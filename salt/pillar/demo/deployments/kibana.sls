deployments:

    kibana_container:
        kibana-frontend:
            host: infra
            activated: False
            activate:
                firewall:
                    basic:
                        kibana-frontend:
                            ip: 192.168.121.109
                            accept:
                                tcp:
                                    http: 80
                services:
                    enabled:
                        - kibana-frontend

            container:
                description: kibana cluster
                volumes:
                    - -v /etc/kibana/kibana.yml:/usr/share/kibana/config/kibana.yml
                    - -v /d/local/data/kibana:/usr/share/kibana/data
                ports:
                    - -p 192.168.121.109:80:5601
                image:   nexus:7083/kibana/kibana:6.4.0
                env: 
                    - -e XPACK_REPORTING_ENABLED=false
                    - -e XPACK_SECURITY_ENABLED=false
                mounts:
                    /etc/kibana/kibana: file
                    /d/local/data/kibana: dir
                storage:
                    - /d/local/data/kibana
                user: 1000
                group: 1000

            config:
                server_name:      kibana
                elasticsearch_url: http://192.168.121.109:9200
                xpack_enabled:     'false'


            filesystem:
                templates:
                    {%raw%}
                    #   server.host: '{{config.server_host if 'server_host' in config else "0"}}'
                    kibana-yml: |
                        server.name: {{config.server_name or 'kibana'}}
                        # Even though this looks like a number it has to be a string - hence the quoting.
                        #server.host: "kibana"
                        server.host: "0.0.0.0"
                        elasticsearch.url: {{config.elasticsearch_url or 'http://elasticsearch:9200' }}
                        xpack.monitoring.ui.container.elasticsearch.enabled: {{config.xpack_enabled or 'false'}}
                        #xpack.security.enabled: false
                        #xpack.reporting.enabled: false
                        #xpack.monitoring.enabled: false
                    {%endraw%}

                dirs:
                    /etc/kibana:
                        user:            1000
                        group:           1000

                files:
                    /etc/kibana/kibana.yml:
                        config_pillar:   ':config'
                        template:        kibana-yml
                        user:            1000
                        group:           1000
