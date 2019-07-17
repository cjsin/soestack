{{ salt.loadtracker.load_pillar(sls) }}

# Overrides and data for testing a USB build in a virtual machine (using a qemu virtual machine network)

cups:

    local_subnet: 192.168.121.*

    management_hosts:
        - 192.168.121.*

demo:
    ips:
        gateway:          192.168.0.1
        infra-gateway-ip: 192.168.0.101

docker:
    config:
        daemon:
            dns: 
                - '!!network.gateway'
                - '!!demo.ips.infra'
            dns-search:
                - '!!network.system_domain'

deployments:
    pxeboot_server:
        soestack_demo:
            config:
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
                                    DOMAIN:            '!!network.system_domain'
                                    SALT_MASTER:       infra.demo.com
                                    GATEWAY:           '!!network.gateway'
                                    NAMESERVER:        '!!demo.ips.infra'
                                    # auto ROLES will use data from node_maps
                                    ROLES:             auto
                                    LAYERS:            soe:demo,site:testing,lan:usb-sv,private:example
                                    #ADD_HOST:
                                    #    - 192.168.121.101,infra.demo.com,infra
                                    #    - 192.168.121.103,nexus.demo.com,nexus
                                    #    - 192.168.0.1,gateway.demo.com,gateway
                                # NOTE: ss_repos entries are mapped to ss.ADD_REPO on the boot commandlin
                                ss_repos: {}
                                # NOTE: ss_hosts entries are mapped to ss.ADD_HOST on the boot commandlin
                                ss_hosts:
                                    # NOTE the demo lan is associated with the ethernet device, 
                                    # this gateway is for that and what clients booted on that network will use
                                    192.168.0.1:       gateway.demo.com gateway
                                    192.168.121.101:   infra.demo.com infra master salt ipa ldap nfs pxe
                                    192.168.121.103:   nexus.demo.com nexus
                                kickstart: http://%http_server%/provision/kickstart/kickstart.cfg
                    devlan:
                        kernel:                os/minimal/images/pxeboot/vmlinuz
                        initrd:                os/minimal/images/pxeboot/initrd.img
                        iface:                 eth0
                        static:                True
                        subnet:                192.168.121

                hosts:
                    client:
                        lan:    devlan
                        append: test-host-override

    grafana_container:
        grafana-cont:
            config:
                ip:     '!!demo.ips.grafana'
                domain: '!!network.system_domain'
                datasources:
                    - access: 'proxy'                        # make grafana perform the requests
                      editable: true                         # whether it should be editable
                      isDefault: true                        # whether this should be the default DS
                      name: 'prometheus'                     # name of the datasource
                      orgId: 1                               # id of the organization to tie this datasource to
                      type: 'prometheus'                     # type of the data source
                      url: 'http://prometheus.demo.com:9090' # url of the prom instance
                      version: 1                             # well, versioning

    ipa_client:
        demo-ipa-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  '!!ipa.server'
                realm:   '!!ipa.realm'
                domain:  '!!network.system_domain'
                ldap:
                    base-dn: '!!ipa.base_dn'

    ipa_master:
        demo-ipa-master:
            config:
                domain: '!!network.system_domain'
                realm:  '!!ipa.realm'
                fqdn:   '!!ipa.server'
                ip:     '!!demo.ips.infra'
                install:
                    dns:
                        forwarders:
                            - '!!network.gateway'
                initial-setup:
                    global-config:
                        defaultemaildomain:  '!!network.system_domain'
    ipa_replica:
        demo-ipa-replica:
            config:
                domain: '!!network.system_domain'
                realm:  '!!ipa.realm'
                fqdn:   '!!ipa.server'
                ip:     '!!demo.ips.infra'
                install:
                    dns:
                        forwarders:
                            - '!!network.gateway'

    managed_hosts:
        demo-ipa-master:
            config:
                domain: '!!network.system_domain'

        demo-ipa-client:
            config:
                domain: '!!network.system_domain'

        demo-ipa-replica:
            config:
                domain: '!!network.system_domain'

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo.com
    nameservers:
        dns1:    '!!demo.ips.infra'
        dns2:    '!!network.gateway'
        dns3:    ''
    search:
        search1: '!!network.system_domain'
        search2: ''
        search3: ''

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
        192.168.0.1:     gateway.demo.com gateway
        192.168.121.101: infra.demo.com infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
        192.168.121.103: nexus.demo.com nexus

    classes:
        gateway:
            sysconfig:
                GATEWAY: '!!network.gateway'
        infra-dns:
            sysconfig:
                DNS1: 127.0.0.1
                DNS2: '!!network.gateway'
                DNS3: ''
        infra-server-netconnected:
            sysconfig:
                # IP for Gateway subnet
                IPADDR1: '!!demo.ips.infra-gateway-ip'
                PREFIX1: '24'
                # Main infra services
                IPADDR2: '!!demo.ips.infra'
                PREFIX2: '24'

node_maps:
    replica1:
        roles: 'role-set:secondary-server-node'
    processor2:
        roles: 'role-set:login-processor-node'
    workstation3:
        roles: 'role-set:developer-workstation-node'

postfix:
    mode: client
    config:
        defaults:
            enabled:             True
            append_dot_mydomain: no
            inet_protocols:      ipv4
            myorigin:            '!!network.system_domain'
            home_mailbox:        ''
            mydomain:            localhost.localdomain
            mydestination:       localhost.$mydomain, localhost.localdomain, localhost
        server:
            inet_interfaces:     '!!demo.ips.infra'
            mydomain:            '!!network.system_domain'
            myorigin:            '!!network.system_domain'
            mydestination:       $myhostname, $mydomain, localhost.$mydomain, localhost.localdomain, localhost
            home_mailbox:        Maildir/
            relayhost:           ''
            relay_domains:       ''
        client: 
            relayhost:           '[infra.demo.com]:25'
            relay_domains:       '!!network.system_domain'
            default_transport:   smtp

ssh:
    authorized_keys:
        root:
            # Change this after the server is built, 
            # or alternatively set ssh:authorized_keys:root:root@infra.demo.com 
            # in your salt/pillar/layers/private/<your-private-layer-name>/private.sls
            root@infra.demo.com: unset
