{{ salt.loadtracker.load_pillar(sls,'host infra') }}


_layers_test:
    host:        {{sls}}
    host-value:  'host-infra'
    test_value:  'host-infra'
    additive:
        - host-infra

layers_test:
    host:        {{sls}}
    host-value:  'host-infra'
    test_value:  'host-infra'
    additive:
        - host-infra

include:
    - demo.deployments.types
    - demo.deployments.ipa-server

# on node infra:
deployments:
    ipa:
        config:
            type:    master
            server:  '!!demo.vars.primary_server'
            fqdn:    '!!demo.vars.primary_server'
            bind_ips:
                httpd: '!!demo.ips.infra'
                named: '!!demo.ips.infra'

    ss-gitlab-runners:
        hosts:
            - {{grains.host}}
        activated:       True
        activated_where: {{sls}}

dhcp:

    # NOTE the following settings are not used for the pxeboot server, IIRC
    dnsmasq:
        enabled: True
        dhcp_only: True 
        range:
            - 192.168.1.20
            - 192.168.1.30
    
        # 8640m is 6 days
        lease_time: 8640

    dhcpd:
        enabled: False
        # 8640m is 6 days
        lease_time: 8640
        subnets:    
            192.168.1.0:
                routers: 192.168.1.1
                netmask: 255.255.255.0

network:
    ipv6:
        # IPA needs ipv6 enabled, but we can do it on the lo interface only
        mode: 'lo-only'

nexus-repos:
    defaults:
        gitlab:   True # add only on the infra server

rsyslog:
    server:
        enabled: True

# Override the runlevel to multi-user for this node
# despite configuring it with desktop packages
runlevel: graphical

tftp:
    implementation: dnsmasq

# Override DNS on the infra server
dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      '!!demo.vars.primary_server'
    nameservers:
        dns1:    127.0.0.1
        dns2:    '!!network.gateway'
        dns3:    ''
    search:
        search1: '!!network.system_domain'
        search2: ''
        search3: ''
