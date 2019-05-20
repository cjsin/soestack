# Overrides and data for the demo test soe lan

cups:

    local_subnet: 10.0.2.*

    management_hosts:
        - 10.0.2.*

network:
    # demo virtual network
    subnet:  10.0.2.0/24
    netmask: 255.255.255.0
    prefix:  24
    gateway: 10.0.2.2

    system_domain: qemu
    
    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        10.0.2.2:        gateway.qemu qateway nexus
        192.168.121.101: infra.demo infra ipa.demo ipa salt.demo salt ldap.demo ldap
