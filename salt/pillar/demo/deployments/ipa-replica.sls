{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ipa_master:
        demo-ipa-master:
            host:            replica
            activated:       True
            activated_where: {{sls}}
            install:
                nuggets-required:
                    - ipa-server

            config:
                domain: demo.com
                realm:  DEMO.COM
                fqdn:   infra.demo.com
                reverse_zone: 121.168.192.in-addr.arpa.
                site:   default
                hosts:  managed-hosts:demo-ipa-master
                install:
                    dns:
                        enabled: True
                        forwarders: []
                bind_ips:
                    httpd: '!!demo.ips.replica1'
                    named: '!!demo.ips.replica1'
