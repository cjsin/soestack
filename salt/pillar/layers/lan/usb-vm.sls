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
                - demo.usb-vm

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
                                    DOMAIN:            demo.usb-vm
                                    SALT_MASTER:       infra.demo.usb-vm
                                    GATEWAY:           192.168.121.101
                                    NAMESERVER:        192.168.121.101
                                    # auto ROLES will use data from node_maps
                                    ROLES:             auto
                                    LAYERS:            soe:demo,site:testing,lan:usb-vm
                                    #ADD_HOST:
                                    #    - 192.168.121.101,infra.demo.usb-vm,infra
                                    #    - 192.168.121.103,nexus.demo.usb-vm,nexus
                                    #    - 192.168.121.1,gateway.demo.usb-vm,gateway
                                ss_repos: {}
                                ss_hosts:
                                    # NOTE the demo lan is associated with the ethernet device, 
                                    # this gateway is for that and what clients booted on that network will use
                                    192.168.121.1:     gateway.demo.usb-vm gateway
                                    192.168.121.101:   infra.demo.usb-vm infra master salt ipa ldap nfs pxe
                                    192.168.121.103:   nexus.demo.usb-vm nexus
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
                domain: demo.usb-vm
                datasources:
                    - access: 'proxy'                       # make grafana perform the requests
                      editable: true                        # whether it should be editable
                      isDefault: true                       # whether this should be the default DS
                      name: 'prometheus'                    # name of the datasource
                      orgId: 1                              # id of the organization to tie this datasource to
                      type: 'prometheus'                    # type of the data source
                      url: 'http://prometheus.demo.usb-vm:9090'  # url of the prom instance
                      version: 1                            # well, versioning

    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.demo.usb-vm
                realm:   DEMO
                domain:  demo.usb-vm
                ldap:
                    base-dn: dc=demo,dc=usb-vm

    ipa_master:
        testenv-master:
            config:
                domain: demo.usb-vm
                realm:  DEMO
                fqdn:   infra.demo.usb-vm
                ip:     192.168.121.101
                install:
                    dns:
                        forwarders:
                            - 192.168.121.1 # virtual machine host
                initial-setup:
                    global-config:
                        defaultemaildomain:  demo.usb-vm

    managed_hosts:
        testenv-master:
            config:
                domain: demo.usb-vm

        testenv-client:
            config:
                domain: demo.usb-vm

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo.usb-vm
    nameservers:
        dns1:    192.168.121.101
        dns2:    192.168.121.1
        dns3:    ''
    search:
        search1: demo.usb-vm
        search2: ''
        search3: ''

ipa:
    base_dn:   dc=demo,dc=usb-vm

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
            aliases:  infra ipa.demo.usb-vm ipa salt.demo.usb-vm salt ldap.demo.usb-vm ldap
            type:     client
            hostfile:
                - '.*'

network:
    # demo virtual network
    subnet:  192.168.121/24
    netmask: 255.255.255.0
    prefix:  24
    gateway: 192.168.121.1
    system_domain: demo.usb-vm
    
    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   gateway.demo.usb-vm gateway
        
        192.168.121.101: infra.demo.usb-vm infra ipa.demo.usb-vm ipa salt.demo.usb-vm salt ldap.demo.usb-vm ldap
        192.168.121.103: nexus.demo.usb-vm nexus

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

postfix:
    config:
        append_dot_mydomain: no
        inet_protocols:     ipv4
        myorigin:           usb-vm
        #myorigin:           demo.usb-vm
        home_mailbox:       ''
        mydomain:           localhost.localdomain
        mydestination:      localhost.$mydomain, localhost.localdomain, localhost
        relayhost:          '[infra.usb-vm]:25'
        relay_domains:      usb-vm
        default_transport:  smtp

ssh:
    authorized_keys:
        root:
            root@infra.demo.usb-vm: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAHwPMVvnL0JEUjfw5dUOGTfWaec5g7qZj1pm8I0m/aZGZs/a4paD08BwzOLjc7NBF0mveYNRIdWNX9AhdbTG/d6uelNOhQ9Tmc6TwV/NVFKNntfZ3mzpy3tGKyIa+UGWttkng07eMwx1ZJFlebmYolIdZbVDo5oQhjnv/3b9gQz22t8JZibWw1YlfDYBvF2xNZ2MuJvTSSUP5lyps6CNgTiTLV0bRCeiOlRqRv1H7EUrR16vVY42DUHg4RvmuqFhwxIHFMtQcOgQ9J/MOGUlaUb8C94bytwZMpyFwdDp7dqtMII3MqsuoLbTrDH2Qsd7ZOd1zC8W4fR3aqbBMh8wD
