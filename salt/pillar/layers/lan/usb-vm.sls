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
                                    GATEWAY:           192.168.121.101
                                    NAMESERVER:        192.168.121.101
                                    # auto ROLES will use data from node_maps
                                    ROLES:             auto
                                    LAYERS:            soe:demo,site:testing,lan:usb-vm
                                    #ADD_HOST:
                                    #    - 192.168.121.101,infra.demo.com,infra
                                    #    - 192.168.121.103,nexus.demo.com,nexus
                                    #    - 192.168.121.1,gateway.demo.com,gateway
                                ss_repos: {}
                                ss_hosts:
                                    # NOTE the demo lan is associated with the ethernet device, 
                                    # this gateway is for that and what clients booted on that network will use
                                    192.168.121.1:     gateway.demo.com gateway
                                    192.168.121.101:   infra.demo.com infra master salt ipa ldap nfs pxe
                                    192.168.121.103:   nexus.demo.com nexus
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
                domain: demo.com
                datasources:
                    - access: 'proxy'                       # make grafana perform the requests
                      editable: true                        # whether it should be editable
                      isDefault: true                       # whether this should be the default DS
                      name: 'prometheus'                    # name of the datasource
                      orgId: 1                              # id of the organization to tie this datasource to
                      type: 'prometheus'                    # type of the data source
                      url: 'http://prometheus.demo.com:9090'  # url of the prom instance
                      version: 1                            # well, versioning

    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.demo.com
                realm:   DEMO
                domain:  demo.com
                ldap:
                    base-dn: dc=demo,dc=com

    ipa_master:
        testenv-master:
            config:
                domain: demo.com
                realm:  DEMO
                fqdn:   infra.demo.com
                ip:     192.168.121.101
                install:
                    dns:
                        forwarders:
                            - 192.168.121.1 # virtual machine host
                initial-setup:
                    global-config:
                        defaultemaildomain:  demo.com

    managed_hosts:
        testenv-master:
            config:
                domain: demo.com

        testenv-client:
            config:
                domain: demo.com

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo.com
    nameservers:
        dns1:    192.168.121.101
        dns2:    192.168.121.1
        dns3:    ''
    search:
        search1: demo.com
        search2: ''
        search3: ''

ipa:
    base_dn:   dc=demo,dc=com

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
            aliases:  infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
            type:     client
            hostfile:
                - '.*'

network:
    # demo virtual network
    subnet:  192.168.121/24
    netmask: 255.255.255.0
    prefix:  24
    gateway: 192.168.121.1
    system_domain: demo.com
    
    hostfile-additions:
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   gateway.demo.com gateway
        
        192.168.121.101: infra.demo.com infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
        192.168.121.103: nexus.demo.com nexus

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
        myorigin:           demo.com
        home_mailbox:       ''
        mydomain:           localhost.localdomain
        mydestination:      localhost.$mydomain, localhost.localdomain, localhost
        relayhost:          '[infra.demo.com]:25'
        relay_domains:      demo.com
        default_transport:  smtp

ssh:
    authorized_keys:
        root:
            root@infra.demo.com: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAHwPMVvnL0JEUjfw5dUOGTfWaec5g7qZj1pm8I0m/aZGZs/a4paD08BwzOLjc7NBF0mveYNRIdWNX9AhdbTG/d6uelNOhQ9Tmc6TwV/NVFKNntfZ3mzpy3tGKyIa+UGWttkng07eMwx1ZJFlebmYolIdZbVDo5oQhjnv/3b9gQz22t8JZibWw1YlfDYBvF2xNZ2MuJvTSSUP5lyps6CNgTiTLV0bRCeiOlRqRv1H7EUrR16vVY42DUHg4RvmuqFhwxIHFMtQcOgQ9J/MOGUlaUb8C94bytwZMpyFwdDp7dqtMII3MqsuoLbTrDH2Qsd7ZOd1zC8W4fR3aqbBMh8wD
