{{ salt.loadtracker.load_pillar(sls) }}

# Overrides and data for the demo test soe lan

demo:
    ips:
        gateway: 192.168.188.1

cups:

    local_subnet: 192.168.121.*

    management_hosts:
        - 192.168.121.*

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo.com
    nameservers:
        dns1:    '!!demo.ips.infra' 
        dns2:    '!!demo.ips.gateway' 
        dns3:    ''
    search:
        search1: demo.com
        search2: ''
        search3: ''


docker:
    config:
        daemon:
            dns: 
                - '!!demo.ips.infra'  # infra server
                - '!!demo.ips.gateway'    # internet gateway in demo environment
            dns-search:
                - demo.com

deployments:
    pxeboot_server:
        soestack_demo:
                lans:
                    defaults:
                        timeout:         0
                        title:           Default Network Boot
                        type:            soestack
                        kernel:          os/minimal/images/pxeboot/vmlinuz
                        initrd:          os/minimal/images/pxeboot/initrd.img
                        ss_provisioning: provision
                        entries:
                            netinstall:
                                ss_settings:
                                    DOMAIN:            demo.com
                                    SALT_MASTER:       infra.demo.com
                                    GATEWAY:           '!!demo.ips.infra'
                                    NAMESERVER:        '!!demo.ips.infra'
                                    ROLES:             role-set:developer-workstation-node
                                    LAYERS:            soe:demo,site:testing,lan:example,private:example
                                kickstart: http://%http_server%/provision/kickstart/kickstart.cfg
                                #stage2:    nfs:nfsvers=4:%nfs_server%:/e/pxe/os/minimal/
                    demo:
                        # For whatever reason  (probably routing) 
                        # since both these network devices ar using the same subnet,
                        # this needs to be eth0 in my test env, not eth1
                        iface:                 eth0
                        subnet:                192.168.121
                        static:                True
                        entries:
                            netinstall:
                                ss_settings:
                                    DOMAIN:            demo.com
                                    ROLES:             basic-node
                                    NAMESERVER:        '!!demo.ips.infra'
                                ss_hosts:
                                    # NOTE the demo lan is associated with the ethernet device, 
                                    # this gateway is for that and what clients booted on that network will use
                                    192.168.121.1:     gateway
                                    192.168.121.101:   infra.demo.com infra master salt ipa ldap nfs pxe
                                    192.168.121.103:   nexus.demo.com nexus


    ipa_client:
        demo-ipa-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.demo.com
                realm:   DEMO.COM
                domain:  demo.com
                site:    testing
                ldap:
                    base-dn: dc=demo,dc=com

    ipa_master:
        demo-ipa-master:
            config:
                domain: demo.com
                realm:  DEMO.COM
                fqdn:   infra.demo.com
                install:
                    dns:
                        forwarders:
                            # modem / wifi
                            - '!!demo.ips.gateway' 
                initial-setup:
                    global-config:
                        defaultemaildomain:  demo.com

    managed_hosts:
        demo-ipa-master:
            config:
                domain: demo.com

        demo-ipa-client:
            config:
                domain: demo.com

ipa:
    # NOTE: IPA uses the REALM to generate the base dn, dc=xxx, not the dns domain
    base_dn:   dc=demo

managed-hosts:
    demo-ipa-client:
        infra:
            ip:       '!!demo.ips.infra' 
            mac:      '52:54:00:d5:19:d5'
            aliases:  infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
            type:     client
            hostfile:
                - '.*'

network:
    # demo virtual network
    subnet:  192.168.121/24
    netmask: 255.255.255.0
    prefix:  24
    gateway: '!!demo.ips.gateway' 
    system_domain: demo.com

    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   wired-gateway
        192.168.188.1:   gateway.demo.com gateway modem
        192.168.121.101: infra.demo.com infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
        192.168.121.103: nexus.demo.com nexus
        10.0.2.15:       client.demo.com client

    classes:
        gateway:
            sysconfig:
                GATEWAY: '!!demo.ips.gateway' 
        lan-wired-gateway:
            sysconfig:
                GATEWAY: '!!demo.ips.gateway' 
        infra-dns:
            sysconfig:
                DNS1: 127.0.0.1
                DNS2: '!!demo.ips.gateway' 
                DNS3: ''

ssh:
    authorized_keys:
        root:
            root@infra.demo.com: unset
