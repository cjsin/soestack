{{ salt.loadtracker.load_pillar(sls) }}

deployments:

    simple_http:
        pxe:
            host:            infra
            activated:       True
            activated_where: {{sls}}

            activate:
                services:
                    enabled:
                        - simple-http-pxe

                firewall:
                    basic:
                        kickstart-http:
                            ip: 192.168.121.101
                            accept:
                                tcp:
                                    http: 9001
            config:
                bind_ip: 192.168.121.101
                port:    9001
                path:    /e/pxe
                user:    nobody

        docs:
            host:            infra
            activated:       True
            activated_where: {{sls}}

            activate:
                services:
                    enabled:
                        - simple-http-docs

                firewall:
                    basic:
                        docs-http:
                            ip: 192.168.121.111
                            accept:
                                tcp:
                                    http: 80
            config:
                bind_ip: 192.168.121.111
                port:    80
                path:    /soestack/htdocs
                # root user is used because it's binding port 80 (under 1024)
                user:    root
