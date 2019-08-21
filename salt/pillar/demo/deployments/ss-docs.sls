{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ss-docs:
        deploy_type:     simple_http
        roles:
            - infra-server-node
        activated:       True
        activated_where: {{sls}}

        activate:
            services:
                enabled:
                    - ss-docs

            firewall:
                basic:
                    docs-http:
                        ip: '!!demo.ips.docs'
                        accept:
                            tcp:
                                http: 80
        config:
            bind_ip: '!!demo.ips.docs'
            port:    80
            path:    /soestack/htdocs
            # root user is used because it's binding port 80 (under 1024)
            user:    root