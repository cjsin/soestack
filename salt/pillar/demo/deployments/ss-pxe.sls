{{ salt.loadtracker.load_pillar(sls) }}

deployments:

    ss-pxe:
        deploy_type:     simple_http
        role:            infra-server-node
        activated:       True
        activated_where: {{sls}}

        activate:
            services:
                enabled:
                    - ss-pxe

            firewall:
                basic:
                    kickstart-http:
                        ip: '!!demo.ips.infra'
                        accept:
                            tcp:
                                http: 9001
        config:
            bind_ip: '!!demo.ips.infra'
            port:    9001
            path:    /e/pxe
            user:    nobody

