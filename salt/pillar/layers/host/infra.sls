_loaded:
    {{sls}}:

nexus-repos:
    defaults:
        gitlab:   True # add only on the infra server

dhcp:

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


rsyslog:
    server:
        enabled: True

# Override the runlevel to multi-user for this node
# despite configuring it with desktop packages
runlevel: multi-user

tftp:
    implementation: dnsmasq


