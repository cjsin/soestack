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
                - 192.168.121.1   # host in VM environment
                - 192.168.121.101 # infra server
            dns-search:
                - usb-vm

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
                                    DOMAIN:            usb-vm
                                    SALT_MASTER:       infra.usb-vm
                                    GATEWAY:           192.168.121.101
                                    NAMESERVER:        192.168.121.101
                                    # auto ROLES will use data from node_maps
                                    ROLES:             auto
                                    LAYERS:            soe:demo,site:testing,lan:usb-vm
                                    #ADD_HOST:
                                    #    - 192.168.121.101,infra.usb-vm,infra
                                    #    - 192.168.121.103,nexus.usb-vm,nexus
                                    #    - 192.168.121.1,gateway.usb-vm,gateway
                                ss_repos: {}
                                ss_hosts:
                                    # NOTE the demo lan is associated with the ethernet device, 
                                    # this gateway is for that and what clients booted on that network will use
                                    192.168.121.1:     gateway.usb-vm gateway
                                    192.168.121.101:   infra.usb-vm infra master salt ipa ldap nfs pxe
                                    192.168.121.103:   nexus.usb-vm nexus
                                kickstart: http://%http_server%/provision/kickstart/kickstart.cfg
                                #stage2:    nfs:%nfs_server%:/e/pxe/os/minimal/
                    usb-vm:
                        kernel:                os/minimal/images/pxeboot/vmlinuz
                        initrd:                os/minimal/images/pxeboot/initrd.img
                        iface:                 eth0
                        static:                True
                        subnet:                192.168.121

                hosts:
                    client:
                        lan:    usb-vm
                        append: test-host-override

    grafana_container:
        grafana-cont:
            config:
                ip:     192.168.121.108
                domain: usb-vm
                datasources:
                    - access: 'proxy'                       # make grafana perform the requests
                      editable: true                        # whether it should be editable
                      isDefault: true                       # whether this should be the default DS
                      name: 'prometheus'                    # name of the datasource
                      orgId: 1                              # id of the organization to tie this datasource to
                      type: 'prometheus'                    # type of the data source
                      url: 'http://prometheus.usb-vm:9090'  # url of the prom instance
                      version: 1                            # well, versioning

    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.usb-vm
                realm:   DEMO
                domain:  usb-vm
                site:    testing
                ldap:
                    base-dn: dc=usb-vm

    ipa_master:
        testenv-master:
            config:
                domain: usb-vm
                realm:  DEMO
                fqdn:   infra.usb-vm
                site:   testing
                ip:     192.168.121.101
                install:
                    dns:
                        forwarders:
                            - 192.168.121.1 # virtual machine host
                initial-setup:

                    automount:
                        locations:
                            - testing

    managed_hosts:
        testenv-master:
            config:
                domain: usb-vm

        testenv-client:
            config:
                domain: usb-vm

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.usb-vm
    nameservers:
        dns1:    192.168.121.101
        dns2:    192.168.121.1
        dns3:    ''
    search:
        search1: usb-vm
        search2: ''
        search3: ''

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
            lan:      usb-vm
            aliases:  infra ipa.usb-vm ipa salt.usb-vm salt ldap.usb-vm ldap
            type:     client
            hostfile:
                - '.*'


network:
    # demo virtual network
    subnet:  192.168.121/24
    netmask: 255.255.255.0
    prefix:  24
    gateway: 192.168.121.1
    system_domain: usb-vm
    
    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   gateway.usb-vm gateway
        
        192.168.121.101: infra.usb-vm infra ipa.usb-vm ipa salt.usb-vm salt ldap.usb-vm ldap
        192.168.121.103: nexus.usb-vm nexus

    classes:
        gateway:
            sysconfig:
                GATEWAY: 192.168.121.1
        infra-dns:
            sysconfig:
                DNS1: 127.0.0.1
                DNS2: 192.168.121.1
                DNS3: ''
                
node_maps:
    pxe-client1:
        roles: 'role-set:developer-workstation-node'
    pxe-client2:
        roles: 'role-set:login-processor-node'
