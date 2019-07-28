{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ss-nexus-mirror:
        deploy_type:     nexus_container
        activated:       False
        activated_where: {{sls}}
        activate:
            services:
                enabled:
                    - ss-nexus-mirror
            firewall:
                basic:
                    ss-nexus-mirror:
                        ip: '!!demo.ips.nexus'
                        accept:
                            tcp:
                                http: 7081
                                registry1: 7082
                                registry2: 7083
                                registry3: 7084
                                registry4: 7085
        container:
            description: Sonatype Nexus OSS 3 Pull-through cache
            image:       sonatype/nexus3:3.16.2
            local_image: True
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
