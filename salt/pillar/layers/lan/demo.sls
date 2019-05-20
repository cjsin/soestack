# Overrides and data for the demo test soe lan

cups:

    local_subnet: 192.168.121.*

    management_hosts:
        - 192.168.121.*

network:
    # demo virtual network
    subnet:  192.168.121/24
    netmask: 255.255.255.0
    prefix:  24
    gateway: 192.168.121.1

    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   wired-gateway
        192.168.188.1:   gateway.demo gateway modem
        10.0.2.15:       client.demo client
        192.168.121.101: infra.demo infra ipa.demo ipa salt.demo salt ldap.demo ldap
