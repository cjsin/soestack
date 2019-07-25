{{ salt.loadtracker.load_pillar(sls) }}

# Overrides and data for the demo test soe lan

demo:
    ips:
        gateway: 192.168.188.1
    macs:
        infra:   '52:54:00:d5:19:d5'

deployments:
    pxebooting:
        config:
            lans:
                defaults:
                    entries:
                        netinstall:
                            ss_settings:
                                ROLES:             role-set:developer-workstation-node
                                LAYERS:            soe:demo,role:G@roles,site:testing,lan:example,host:G@host,lan-host:lan:G@layers:lan+host:G@host,private:example.private

                # extra demo lan for pxebooting nodes with quick-install minimal basic node type 
                demo:
                    # For whatever reason  (probably routing) 
                    # since both these network devices are using the same subnet,
                    # this needs to be eth0 in my test env, not eth1
                    iface:                 eth0
                    subnet:                192.168.122 # NOTE this is different from the main 192.168.121.x subnet
                    static:                True
                    entries:
                        netinstall:
                            ss_settings:
                                DOMAIN:            '!!demo.vars.system_domain'
                                ROLES:             basic-node
                                NAMESERVER:        '!!demo.ips.infra'
                            ss_hosts:
                                # NOTE the demo lan is associated with the ethernet device, 
                                # this gateway is for that and what clients booted on that network will use
                                192.168.121.1:     gateway

    ipa:
        config:
            install:
                dns:
                    forwarders:
                        - '!!demo.ips.gateway' 
{# 
managed-hosts:
    hostfile-hosts:
        infra:
            ip:       '!!demo.ips.infra' 
            mac:      '
            aliases:  infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
            type:     client
            hostfile:
                - '.*' #}

network:

    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   wired-gateway
        192.168.188.1:   gateway.demo.com gateway modem
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
