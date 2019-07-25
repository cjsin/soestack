{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    # The EPEL online repo is broken currently for 'yum' clients due
    # to the 'zchunk' support which was added. Fix submitted in bug
    # tracker, but no sign of them implementing it as the maintainer is
    # on holidays for 2 months.
    # So, creating here a http service to provide the epel bootstrap packages
    # (containing just what's used in this demo)
    ss-epel:
        deploy_type: simple_http

        role:            infra-server-node
        activated:       True
        activated_where: {{sls}}
        activate:
            services:
                enabled:
                    - ss-epel

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
