_loaded:
    {{sls}}:

# Overrides and data for the demo test soe lan, 
# which is set up on a libvirt virtual network,
# and intended for running vagrant images with two network
# devices ( therefore the eth0 network is left for vagrant
# and the eth1 device is configured as normal)

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
                - qemu

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
                                    DOMAIN:            qemu
                                    SALT_MASTER:       infra.qemu
                                    GATEWAY:           192.168.121.101
                                    NAMESERVER:        192.168.121.101
                                    ROLES:             role-set:developer-workstation-node
                                    LAYERS:            soe:demo,site:testing,lan:qemu
                                kickstart: http://%http_server%/provision/kickstart/kickstart.cfg
                                #stage2:    nfs:%nfs_server%:/e/pxe/os/minimal/
                    qemu:
                        kernel:                os/minimal/images/pxeboot/vmlinuz
                        initrd:                os/minimal/images/pxeboot/initrd.img
                        iface:                 eth1
                        static:                True
                        subnet:                192.168.121
                        # entries:
                        #     # Example custom entry
                        #     custom:
                        #         title:    '^Custom Kickstart (Centos7 custom)'
                        #         ss_settings:
                        #             DOMAIN:            qemu
                        #             ROLES:             role-set:developer-workstation-node
                        #             LAYERS:            soe:demo,site:testing,lan:qemu
                        #         ss_hosts:
                        #             # To nodes booting within the libvirt/qemu/vagrant test network the nexus server and gateway are 10.0.2.2
                        #             192.168.121.1:     gateway gateway.qemu
                        #             192.168.121.101:   infra.qemu infra master salt ipa ldap nfs pxe
                        #             192.168.121.103:   nexus.qemu nexus
                        #         append:    noquiet custom-test
                        #         kickstart: http://%http_server%/provision/kickstart/kickstart-custom.cfg
                        #         stage2:    nfs:%nfs_server%:/e/pxe/os/custom/

                hosts:
                    client:
                        lan:    qemu
                        append: test-host-override
                    pxe-client1:
                        ss_settings:
                            ROLES: basic-node

    grafana_container:
        grafana-cont:
            config:
                ip:     192.168.121.108
                domain: qemu
                datasources:
                    - access: 'proxy'                       # make grafana perform the requests
                      editable: true                        # whether it should be editable
                      isDefault: true                       # whether this should be the default DS
                      name: 'prometheus'                    # name of the datasource
                      orgId: 1                              # id of the organization to tie this datasource to
                      type: 'prometheus'                    # type of the data source
                      url: 'http://prometheus.qemu:9090'    # url of the prom instance
                      version: 1                            # well, versioning

    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.qemu
                realm:   DEMO
                domain:  qemu
                site:    qemu
                ldap:
                    base-dn: dc=qemu

    ipa_master:
        testenv-master:
            config:
                domain: qemu
                realm:  DEMO
                fqdn:   infra.qemu
                site:   qemu
                ip:     192.168.121.101
                install:
                    dns:
                        forwarders:
                            - 192.168.121.1 # virtual machine host
                initial-setup:

                    automount:
                        locations:
                            - qemu

    managed_hosts:
        testenv-master:
            config:
                domain: qemu

        testenv-client:
            config:
                domain: qemu

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.qemu
    nameservers:
        dns1:    192.168.121.101
        dns2:    192.168.121.1
        dns3:    ''
    search:
        search1: qemu
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
            lan:      qemu
            aliases:  infra ipa.qemu ipa salt.qemu salt ldap.qemu ldap
            type:     client
            hostfile:
                - '.*'


network:
    # demo virtual network
    subnet:  192.168.121/24
    netmask: 255.255.255.0
    prefix:  24
    gateway: 192.168.121.1
    system_domain: qemu
    
    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   gateway.qemu gateway
        
        192.168.121.101: infra.qemu infra ipa.qemu ipa salt.qemu salt ldap.qemu ldap
        192.168.121.103: nexus.qemu nexus

    classes:
        gateway:
            sysconfig:
                GATEWAY: 192.168.121.1
        infra-dns:
            sysconfig:
                DNS1: 127.0.0.1
                DNS2: 192.168.121.1
                DNS3: ''
                

