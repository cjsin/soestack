_loaded:
    {{sls}}:

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
    gateway: 192.168.188.1
    system_domain: demo

    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   wired-gateway
        192.168.188.1:   gateway.demo gateway modem
        192.168.121.101: infra.demo infra ipa.demo ipa salt.demo salt ldap.demo ldap
        192.168.121.103: nexus.demo nexus
        10.0.2.15:       client.demo client

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo
    nameservers:
        dns1:    192.168.121.101
        dns2:    192.168.188.1
        dns3:    ''
    search:
        search1: demo
        search2: ''
        search3: ''


docker:
    config:
        daemon:
            dns: 
                - 192.168.121.101 # infra server
                - 192.168.188.1   # internet gateway in demo environment
            dns-search:
                - qemu

deployments:
    pxeboot_server:
        soestack_demo:
                lans:
                    demo:
                        # For whatever reason  (probably routing) 
                        # since both these network devices ar using the same subnet,
                        # this needs to be eth0 in my test env, not eth1
                        iface:                 eth0
                        subnet:                192.168.121
                        static:                True
                        entries:
                            netinstall: # test resilience with empty entry
                                ss_settings:
                                    DOMAIN:            demo
                                    ROLES:             basic-node
                                    NAMESERVER:        192.168.121.101
                                ss_hosts:
                                    # NOTE the demo lan is associated with the ethernet device, 
                                    # this gateway is for that and what clients booted on that network will use
                                    192.168.121.1:     gateway
                                    192.168.121.101:   infra.demo infra master salt ipa ldap nfs pxe
                                    192.168.121.103:   nexus.demo nexus


    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.demo
                realm:   DEMO
                domain:  demo
                site:    demo
                ldap:
                    base-dn: dc=demo

    ipa_master:
        testenv-master:
            config:
                domain: demo
                realm:  DEMO
                fqdn:   infra.demo
                site:   demo
                install:
                    dns:
                        forwarders:
                            - 192.168.188.1 # modem / wifi
                initial-setup:

                    automount:
                        locations:
                            - demo

    managed_hosts:
        testenv-master:
            config:
                domain: demo

        testenv-client:
            config:
                domain: demo

managed-hosts:
    testenv-client:
        infra:
            ip:       192.168.121.101
            mac:      '52:54:00:d5:19:d5'
            lan:      demo
            aliases:  infra ipa.demo ipa salt.demo salt ldap.demo ldap
            type:     client
            hostfile:
                - '.*'

network:
    classes:
        gateway:
            sysconfig:
                GATEWAY: 192.168.188.1
        lan-wired-gateway:
            sysconfig:
                GATEWAY: 192.168.121.1
        infra-dns:
            sysconfig:
                DNS1: 127.0.0.1
                DNS2: 192.168.188.1
                DNS3: ''
