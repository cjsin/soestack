deployments:
    nexus_container:
        nexus-mirror:
            host: infra
            activated: False
            activate:
                services:
                    enabled:
                        - nexus-mirror
                firewall:
                    basic:
                        nexus-mirror-frontend:
                            ip: 192.168.121.103
                            accept:
                                tcp:
                                    http: 7081
                                    registry1: 7082
                                    registry2: 7083
                                    registry3: 7084
                                    registry4: 7085
            container:
                description: Sonatype Nexus OSS 3 Pull-through cache
                image:       sonatype/nexus3:3.13.0
                volumes:
                    - -v /d/local/data/nexus:/nexus-data
                ports: 
                    - -p 192.168.121.103:7081-7085:8081-8085
                entrypoint: /bin/bash
                options:    
                    -  -c "/opt/sonatype/start-nexus-repository-manager.sh > /nexus-data/service.log 2>&1"
                storage:
                    - /d/local/data/nexus
                user: 200
                group: 200
