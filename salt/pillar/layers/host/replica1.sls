{{ salt.loadtracker.load_pillar(sls,'host infra') }}

include:
    - demo.deployments.types
    - demo.deployments.ipa-server

# on node replica1:
deployments:
    ipa:
        config:
            type:    replica
            server:  replica1.demo.com
            fqdn:    replica1.demo.com
            
            bind_ips:
                httpd: '!!demo.ips.replica1'
                named: '!!demo.ips.replica1'
