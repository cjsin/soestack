{{ salt.loadtracker.load_pillar(sls) }}

rsyslog:
    enabled: True

    client:
        enabled: True
        send: {}
        # Example send specification
        #    192.168.121.101:
        #        port:     2514
        #        protocol: relp

    server:
        enabled: True
        firewall:
            basic:
                syslog-server:
                    accept:
                        tcp:
                            relp: 2514
                            
