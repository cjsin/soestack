deployments:

    grafana_container:

        grafana-cont:

            host: infra
            activated: True

            activate:
                services:
                    enabled:
                        - grafana-cont
                firewall:
                    basic:
                        grafana-frontend:
                            ip: 192.168.121.108
                            accept:
                                tcp:
                                    http: 80
                                    https: 443

            container:
                image:   grafana/grafana:5.2.3

                volumes:
                    - -v /d/local/data/grafana:/var/lib/grafana
                    - -v /etc/ipa/ca.crt:/etc/grafana/ca.crt
                    - -v /etc/grafana/grafana.ini:/etc/grafana/grafana.ini
                    - -v /etc/grafana/ldap.toml:/etc/grafana/ldap.toml

                ports:
                    - -p 192.168.121.108:80:8080
                    - -p 192.168.121.108:443:443

                user:      grafana
                group:     grafana 
                dir_mode:  '0700'
                file_mode: '0600'

                options: 

                mounts:
                    /etc/grafana:          dir
                    /d/local/data/grafana: dir

                storage:
                    - /d/local/data/grafana

            config:
                grafana_url: http://nexus:7081/repository/interwebs/grafana.com
                hostname:    grafana
                port:        8080
                data_path:   /dl/local/data/grafana
                
            filesystem:
                templates:
                    grafana-ini:         salt://deployments/grafana_container/grafana.ini.jinja
                    grafana-ldap-toml:   salt://deployments/grafana_container/grafana-ldap.toml.jinja
                defaults:
                    user:            472
                    group:           472
                    dir_mode:        '0700'
                    file_mode:       '0600'

                dirs:
                    /etc/grafana:
                    /d/local/data/grafana:
                files:
                    /etc/grafana/grafana.ini:
                        config_pillar:   :config
                        template:        grafana-ini
                    /etc/grafana/ldap.toml:
                        config_pillar:   :config
                        template:        grafana-ldap-toml
