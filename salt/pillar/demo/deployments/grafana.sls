{{ salt.loadtracker.load_pillar(sls) }}

deployments:

    ss-grafana:
        deploy_type: grafana_container

        roles:
            - grafana-node
            
        activated: False
        activated_where: {{sls}}

        activate:
            services:
                enabled:
                    - ss-grafana
            firewall:
                basic:
                    grafana-frontend:
                        ip: '!!demo.ips.grafana'
                        accept:
                            tcp:
                                http: 80
                                https: 443

        require-exists:
            file:
                /etc/ipa/ca.crt:

        container:
            image:   grafana/grafana:5.2.3

            volumes:
                - -v /d/local/data/grafana:/var/lib/grafana
                - -v /etc/ipa/ca.crt:/etc/grafana/ca.crt
                - -v /etc/grafana/grafana.ini:/etc/grafana/grafana.ini
                - -v /etc/grafana/ldap.toml:/etc/grafana/ldap.toml
                - -v /etc/grafana/provisioning:/etc/grafana/provisioning

            ports:
                - -p 192.168.121.108:80:9991
                - -p 192.168.121.108:443:443

            user:      grafana
            group:     grafana 
            dir_mode:  '0700'
            file_mode: '0600'

            options: 

            mounts:
                /etc/grafana:              dir
                /etc/grafana/provisioning: dir
                /d/local/data/grafana:     dir

            storage:
                - /d/local/data/grafana
                - /etc/grafana/provisioning

        config:
            grafana_url: http://nexus:7081/repository/interwebs/grafana.com
            hostname:    grafana
            port:        9991
            data_path:   /dl/local/data/grafana
            ip:          ''
            domain:      ''
            cert:        ''
            datasources: []
            
        filesystem:
            templates:
                grafana-ini:             salt://templates/deployment/grafana_container/grafana.ini.jinja
                grafana-ldap-toml:       salt://templates/deployment/grafana_container/grafana-ldap.toml.jinja
                grafana-dashboards-yml:  salt://templates/deployment/grafana_container/dashboards/dashboards.yaml.jinja
                grafana-datasources-yml: salt://templates/deployment/grafana_container/datasources/datasources.yaml.jinja
            defaults:
                user:            472
                group:           472
                dir_mode:        '0700'
                file_mode:       '0600'

            dirs:
                /etc/grafana:
                /etc/grafana/provisioning:
                /etc/grafana/provisioning/dashboards:
                /etc/grafana/provisioning/datasources:
                /d/local/data/grafana:
                /d/local/data/grafana/conf:

            files:
                /etc/grafana/grafana.ini:
                    config_pillar:   :config
                    template:        grafana-ini
                /etc/grafana/ldap.toml:
                    config_pillar:   :config
                    template:        grafana-ldap-toml
                /etc/grafana/provisioning/dashboards/dashboards.yaml:
                    template:        grafana-dashboards-yml
                /etc/grafana/provisioning/datasources/datasources.yaml:
                    config_pillar:   :config
                    template:        grafana-datasources-yml
                /etc/grafana/provisioning/dashboards/host-stats.json:
                    source:          salt://templates/deployment/grafana_container/dashboards/Host-Stats.json
