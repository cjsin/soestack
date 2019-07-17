{{ salt.loadtracker.load_pillar(sls) }}

deployments:

    simple_http:

        # The EPEL online repo is broken currently for 'yum' clients due
        # to the 'zchunk' support which was added. Fix submitted in bug
        # tracker, but no sign of them implementing it as the maintainer is
        # on holidays for 2 months.
        # So, creating here a http service to provide the epel bootstrap packages
        # (containing just what's used in this demo)
        epel:
            host:            infra
            activated:       True
            activated_where: {{sls}}
            activate:
                services:
                    enabled:
                        - simple-http-epel

                firewall:
                    basic:
                        epel-http:
                            ip: '!!demo.ips.infra'
                            accept:
                                tcp:
                                    http: 9002
            config:
                bind_ip: '!!demo.ips.infra'
                port:    9002
                path:    /e/bundled/bootstrap-pkgs/epel
                user:    nobody

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
                            ip: '!!demo.ips.infra'
                            accept:
                                tcp:
                                    http: 9001
            config:
                bind_ip: '!!demo.ips.infra'
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
