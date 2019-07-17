{{ salt.loadtracker.load_pillar(sls) }}

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
                - '!!demo.ips.gateway'    # host in VM environment
                - '!!demo.ips.infra'  # infra server
            dns-search:
                - demo.com

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
                                    DOMAIN:            demo.com
                                    SALT_MASTER:       infra.demo.com
                                    GATEWAY:           '!!demo.ips.infra'
                                    NAMESERVER:        '!!demo.ips.infra'
                                    ROLES:             role-set:developer-workstation-node
                                    LAYERS:            soe:demo,site:testing,lan:qemu,private:example
                                kickstart: http://%http_server%/provision/kickstart/kickstart.cfg
                                #stage2:    nfs:nfsvers=4:%nfs_server%:/e/pxe/os/minimal/
                    devlan:
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
                        #             DOMAIN:            demo.com
                        #             ROLES:             role-set:developer-workstation-node
                        #             LAYERS:            soe:demo,site:testing,lan:qemu,private:example
                        #         ss_hosts:
                        #             # To nodes booting within the libvirt/qemu/vagrant test network the nexus server and gateway are 10.0.2.2
                        #             192.168.121.1:     gateway gateway.demo.com
                        #             192.168.121.101:   infra.demo.com infra master salt ipa ldap nfs pxe
                        #             192.168.121.103:   nexus.demo.com nexus
                        #         append:    noquiet custom-test
                        #         kickstart: http://%http_server%/provision/kickstart/kickstart-custom.cfg
                        #         stage2:    nfs:nfsvers=4:%nfs_server%:/e/pxe/os/custom/

                hosts:
                    client:
                        lan:    devlan
                        append: test-host-override
                    replica1:
                        ss_settings:
                            ROLES: auto

    grafana_container:
        grafana-cont:
            config:
                ip:     '!!demo.ips.grafana'
                domain: demo.com
                datasources:
                    - access: 'proxy'                       # make grafana perform the requests
                      editable: true                        # whether it should be editable
                      isDefault: true                       # whether this should be the default DS
                      name: 'prometheus'                    # name of the datasource
                      orgId: 1                              # id of the organization to tie this datasource to
                      type: 'prometheus'                    # type of the data source
                      url: 'http://prometheus.demo.com:9090'    # url of the prom instance
                      version: 1                            # well, versioning

    ipa_client:
        demo-ipa-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.demo.com
                realm:   DEMO
                domain:  demo.com
                ldap:
                    base-dn: '!!ipa.base_dn'

    ipa_master:
        demo-ipa-master:
            config:
                domain: demo.com
                realm:  DEMO
                fqdn:   infra.demo.com
                ip:     '!!demo.ips.infra'
                install:
                    dns:
                        forwarders:
                            - '!!demo.ips.gateway' # virtual machine host
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

ipa:
    # NOTE: IPA uses the REALM to generate the base dn, dc=xxx, not the dns domain
    base_dn:   dc=demo

ipa-configuration:
    dns:
        reverse-zones:
            # Extra 10.0.2 network for the libvirt/qemu kickstart clients
            2.0.10.in-addr.arpa: 

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
        192.168.121.1:   gateway.demo.com gateway
        
        192.168.121.101: infra.demo.com infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
        192.168.121.103: nexus.demo.com nexus

    classes:
        gateway:
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

