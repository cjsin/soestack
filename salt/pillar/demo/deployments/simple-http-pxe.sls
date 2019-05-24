_loaded:
    {{sls}}:

deployments:

    simple_http:
        pxe:
            host: infra
            activated: True
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
                port: 9001
                path: /e/pxe
