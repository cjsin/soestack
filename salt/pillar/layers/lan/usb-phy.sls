_loaded:
    {{sls}}:

# Overrides and data for testing a USB build in a virtual machine (using a qemu virtual machine network)

cups:

    local_subnet: 192.168.121.*

    management_hosts:
        - 192.168.121.*

docker:
    config:
        daemon:
            dns: 
                - 192.168.0.1     # network gateway/router/modem
                - 192.168.121.101 # infra server
            dns-search:
                - demo.usb.demo-phy

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
                                    DOMAIN:            demo.usb-phy
                                    SALT_MASTER:       infra.demo.usb-phy
                                    GATEWAY:           192.168.0.1
                                    NAMESERVER:        192.168.121.101
                                    ROLES:             role-set:developer-workstation-node
                                    LAYERS:            soe:demo,site:testing,lan:usb-phy
                                kickstart: http://%http_server%/provision/kickstart/kickstart.cfg
                    usb-phy:
                        kernel:                os/minimal/images/pxeboot/vmlinuz
                        initrd:                os/minimal/images/pxeboot/initrd.img
                        iface:                 eth0
                        static:                True
                        subnet:                192.168.121

                hosts:
                    client:
                        lan:    usb-phy
                        append: test-host-override

    grafana_container:
        grafana-cont:
            config:
                ip:     192.168.121.108
                domain: demo.usb-phy
                datasources:
                    - access: 'proxy'                       # make grafana perform the requests
                      editable: true                        # whether it should be editable
                      isDefault: true                       # whether this should be the default DS
                      name: 'prometheus'                    # name of the datasource
                      orgId: 1                              # id of the organization to tie this datasource to
                      type: 'prometheus'                    # type of the data source
                      url: 'http://prometheus.demo.usb-phy:9090' # url of the prom instance
                      version: 1                            # well, versioning

    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.demo.usb-phy
                realm:   DEMO
                domain:  demo.usb-phy
                ldap:
                    base-dn: dc=demo,dc=usb-phy

    ipa_master:
        testenv-master:
            config:
                domain: demo.usb-phy
                realm:  DEMO
                fqdn:   infra.demo.usb-phy
                ip:     192.168.121.101
                install:
                    dns:
                        forwarders:
                            - 192.168.0.1 # interwebs gateway
                initial-setup:
                    global-config:
                        defaultemaildomain:  demo.usb-phy

    managed_hosts:
        testenv-master:
            config:
                domain: demo.usb-phy

        testenv-client:
            config:
                domain: demo.usb-phy

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo.usb-phy
    nameservers:
        dns1:    192.168.121.101
        dns2:    192.168.0.1
        dns3:    ''
    search:
        search1: demo.usb-phy
        search2: ''
        search3: ''

ipa:
    base_dn:   dc=demo,dc=usb-phy

ipa-configuration:
    dns:
        reverse-zones:
            # Extra 10.0.2 network for the libvirt/qemu kickstart clients
            2.0.10.in-addr.arpa: 

managed-hosts:
    testenv-client:
        infra:
            ip:       192.168.121.101
            mac:      '52:54:00:d5:19:d5'
            lan:      usb-phy
            aliases:  infra ipa.demo.usb-phy ipa salt.demo.usb-phy salt ldap.demo.usb-phy ldap
            type:     client
            hostfile:
                - '.*'


network:
    # demo virtual network
    subnet:  192.168.121/24
    netmask: 255.255.255.0
    prefix:  24
    gateway: 192.168.0.1
    system_domain: demo.usb-phy
    
    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.0.1:     gateway.demo.usb-phy gateway
        
        192.168.121.101: infra.demo.usb-phy infra ipa.demo.usb-phy ipa salt.demo.usb-phy salt ldap.demo.usb-phy ldap
        192.168.121.103: nexus.demo.usb-phy nexus

    classes:
        gateway:
            sysconfig:
                GATEWAY: 192.168.0.1
        infra-dns:
            sysconfig:
                DNS1: 127.0.0.1
                DNS2: 192.168.0.1
                DNS3: ''

ssh:
    authorized_keys:
        root:
            root@infra.demo.usb-phy: unset
