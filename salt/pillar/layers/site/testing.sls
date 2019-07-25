{{ salt.loadtracker.load_pillar(sls,'testing') }}

# Overrides for the testing site

_layers_test:
    site:       {{sls}}
    site_value: 'site-testing'
    test_value: 'site-testing'
    additive:
        - site-testing

layers_test:
    site:       {{sls}}
    site_value: 'site-testing'
    test_value: 'site-testing'
    additive:
        - site-testing

demo:
    vars:
        infra:          infra.demo.com
        system_domain:  demo.com
        ipa_realm:      DEMO.COM
        primary_server: infra.demo.com
        reverse_zone:   '121.168.192.in-addr.arpa.'
        ipa_base_dn:    dc=demo,dc=com

    passwords: 
        public-default: admin123
        nexus:          '!!demo.passwords.public-default'
        ipa:
            master:     '!!demo.passwords.public-default'
            admin:      '!!demo.passwords.public-default'
            ds:         random

    ips:
        gateway:         192.168.121.1
        infra:           192.168.121.101
        wildcard:        192.168.121.102
        nexus:           192.168.121.103
        gitlab:          192.168.121.104
        mattermost:      192.168.121.105
        pages:           192.168.121.106 
        gitlab-registry: 192.168.121.107 
        dashboard:       192.168.121.108
        grafana:         '!!demo.ips.dashboard'
        prometheus:      '!!demo.ips.dashboard'
        elk:             192.168.121.109
        elasticsearch:   '!!demo.ips.elk'
        kibana:          '!!demo.ips.elk'
        master:          192.168.121.110
        docs:            192.168.121.111
        nginx:           192.168.121.112

        printer:         192.168.121.215

        pxe-client1:     192.168.121.241
        pxe-client2:     192.168.121.242
        pxe-client3:     192.168.121.243
        replica1:        '!!demo.ips.pxe-client1'
        processor2:      '!!demo.ips.pxe-client2'
        workstation3:    '!!demo.ips.pxe-client3'

##############################
# Beyond this point, try to keep it alphabetical for the toplevel keys
##############################

cups:
    local_subnet: 192.168.121.*
    listen_address: 0.0.0.0:631

    management_hosts:
        - 192.168.121.*
        - infra

    printer_default:   example-printer
    printers:
        defaults:
            properties:
                Accepting: 'Yes'
                Shared:    'Yes'
                JobSheets: none none
                QuotaPeriod: 0
                PageLimit: 0
                KLimit: 0
                OpPolicy: default
                ErrorPolicy: stop-printer
        Cups-PDF:
            Info: Cups-PDF
            MakeModel: Generic CUPS-PDF Printer
            uri_type:  cups-pdf:/
            uri_path:  ''
        example-printer:
            Info:      Example printer
            MakeModel: Example printer (recommended)
            uri_path: '!!demo.ips.printer'
            uri_type:  socket://
            other_config: |-
                Attribute marker-colors \#000000,#000000
                Attribute marker-levels -1,81
                Attribute marker-names Black Toner Cartridge,Drum Unit
                Attribute marker-types toner,opc
                Attribute marker-change-time 1457180115

deployments:

    dovecot:
        activated:       True
        activated_where: {{sls}}


    ss-grafana:
        activated:       True
        activated_where: {{sls}}
        config:
            ip:          '!!demo.ips.grafana'
            domain:      '!!demo.vars.system_domain'
            datasources:
                # NOTE the indenting on this next bit is very picky. all the keys must line up
                -   access: 'proxy'                        # make grafana perform the requests
                    editable: true                         # whether it should be editable
                    isDefault: true                        # whether this should be the default DS
                    name: 'prometheus'                     # name of the datasource
                    orgId: 1                               # id of the organization to tie this datasource to
                    type: 'prometheus'                     # type of the data source
                    url: 'http://prometheus.demo.com:9090' # url of the prom instance
                    version: 1                             # well, versioning


    ipa-hosts:
        config:
            domain: '!!network.system_domain'

    hostfile-hosts:
        config:
            domain: '!!network.system_domain'

    ipa:
        activated:       True
        activated_where: {{sls}}
        roles:
            - ipa-member-node
            - ipa-server-node
        config:
            server:       '!!demo.vars.primary_server'
            server_ip:    '!!demo.ips.infra'
            realm:        '!!demo.vars.ipa_realm'
            domain:       '!!demo.vars.system_domain'
            fqdn:         '!!demo.vars.primary_server'
            ip:           '!!demo.ips.infra'
            site:         testing
            default_site: testing
            reverse_zone: '!!demo.vars.reverse_zone'
            passwords:    '!!demo.passwords.ipa'

            ldap:
                base-dn: '!!demo.vars.ipa_base_dn'
            initial-setup:
                global-config:
                    defaultemaildomain:  '!!network.system_domain'
                automount:
                    locations:
                        - testing
            install:
                dns:
                    enabled: True
                    forwarders:
                        - '!!network.gateway'


    # Override and Disable various deployments here (override some activated by node roles) until I have more RAM
    #    gitlab-runner:
    #        hosts: []
    #        activated:       False
    #        activated_where: {{sls}}
    gitlab:
        activated:       True
        activated_where: {{sls}}
        config:
            hostname:     gitlab.demo.com

    ss-elk:
        activated:       False
        activated_where: {{sls}}

    ss-kibana:
        activated:       False
        activated_where: {{sls}}

    ss-logstash-sys:
        activated:       True
        activated_where: {{sls}}

    nexus-mirror:
        activated:       True
        activated_where: {{sls}}

    phpldapadmin:
        activated:       True
        activated_where: {{sls}}

    ss-prometheus:
        activated:       True
        activated_where: {{sls}}

    pxebooting:
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
                                SALT_MASTER:       '!!demo.vars.primary_server'
                                GATEWAY:           '!!network.gateway'
                                NAMESERVER:        '!!demo.ips.infra'
                                # auto ROLES will use data from node_maps
                                ROLES:             auto
                                # NOTE that each lan layer should override LAYERS to set the 'lan:' part here'
                                LAYERS:            soe:demo,role:G@roles,site:testing,lan:default,host:G@host,lan-host:lan:G@layers:lan+host:G@host,private:example.private
                                #ADD_HOST:
                                #    - 192.168.121.101,infra.demo.com,infra
                                #    - 192.168.121.103,nexus.demo.com,nexus
                            # NOTE: ss_repos entries are mapped to ss.ADD_REPO on the boot commandlin
                            ss_repos: {}
                            # NOTE: ss_hosts entries are mapped to ss.ADD_HOST on the boot commandlin
                            ss_hosts:
                                192.168.121.101:   infra.demo.com infra master salt ipa ldap nfs pxe
                                192.168.121.103:   nexus.demo.com nexus
                                # NOTE an IP address should be added here for the gateway, in the lan layer

                            kickstart: http://%http_server%/provision/kickstart/kickstart.cfg
                devlan:
                    kernel:                os/minimal/images/pxeboot/vmlinuz
                    initrd:                os/minimal/images/pxeboot/initrd.img
                    iface:                 eth0
                    static:                True
                    subnet:                192.168.121


dns:
    # NOTE this will be overridden for server nodes
    server:      '!!demo.vars.primary_server'
    nameservers:
        dns1:    '!!demo.ips.infra'
        dns2:    '!!network.gateway'
        dns3:    ''
    search:
        search1: '!!network.system_domain'
        search2: ''
        search3: ''

docker:
    config:
        daemon:
            # This could be set per-lan (in the lan layer)
            # but alternatively we can use the '!!' shortcut here and just
            # define those values in the lan layer
            dns: 
                - '!!demo.ips.gateway'
                - '!!demo.ips.infra'
            #dns-opts:
            #    #- 'ndots:0'
            dns-search:
                - '!!network.system_domain'
            insecure-registries:
                # docker-ce
                - nexus:7082
                # elasticco
                - nexus:7083
                # k8s.gcr.io
                - nexus:7084
                # unused
                # Misc (uploaded manually)
                - nexus:7085
                - gitlab-registry:5000
            
            # disable-legacy-registry: True

ipa:
    # NOTE: IPA uses the REALM to generate the base dn, dc=xxx, not the dns domain
    server:       '!!demo.vars.primary_server'
    server_ip:    '!!demo.ips.infra'
    base_dn:      '!!demo.vars.ipa_base_dn'
    bind_user:    bind-user
    realm:        '!!demo.vars.ipa_realm'
    domain:       '!!network.system_domain'
    #primary_zone: 192.168.121.0/24
    reverse_zone: '!!demo.vars.reverse_zone'
    default_site: testing
    site:         testing

ipa-initial-setup:
    automount:
        locations:
            - testing

managed-hosts:
    hostfile-hosts:
        infra:
            ip:       '!!demo.ips.infra'
            mac:      '!!demo.macs.infra'
            aliases:  infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
            type:     client
            hostfile:
                - '.*'

    ipa-hosts:
        infra.demo.com:
            ip:      '!!demo.ips.infra'
            aliases: ipa
            type:    dns
        replica1:
            ip:       '!!demo.ips.replica1'
            mac:      '!!demo.macs.replica1'
            type:     client
            hostfile:
                - replica1
        processor2:
            ip:       '!!demo.ips.processor2'
            mac:      '!!demo.macs.processor2'
            type:     client
            hostfile:
                - processor2
        workstation3:
            ip:       '!!demo.ips.workstation3'
            mac:      '!!demo.macs.workstation3'
            type:     client
            hostfile:
                - workstation3

        wildcard:
            ip:       '!!demo.ips.wildcard'
            type:     dns 
            aliases:  nginx.demo.com nginx wildcard
        nexus:
            ip:       '!!demo.ips.nexus'
            type:     dns 
        gitlab:
            ip:       '!!demo.ips.gitlab'
            type:     dns 
            aliases:  gitlab.demo.com
        mattermost.demo.com:
            ip:       '!!demo.ips.mattermost'
            type:     dns 
            aliases:  mattermost
        pages.demo.com:
            ip:       '!!demo.ips.pages'
            type:     dns
            aliases:  pages
        gitlab-registry.demo.com:
            ip:       '!!demo.ips.gitlab-registry'
            type:     dns
            aliases:  gitlab-registry
        grafana:
            ip:       '!!demo.ips.grafana'
            type:     dns 
            aliases:  prometheus.demo.com grafana prometheus
        kibana:
            ip:       '!!demo.ips.kibana'
            type:     dns 
            aliases:  elasticsearch.demo.com kibana elasticsearch
        master:
            ip:       '!!demo.ips.master'
            type:     dns 
            aliases:  master.demo.com master k8s.demo.com k8s
        docs:
            ip:       '!!demo.ips.docs'
            type:     dns 
            aliases:  docs.demo.com docs

network:
    # demo network for testing site
    subnet:        192.168.121/24
    netmask:       255.255.255.0
    prefix:        24
    gateway:       '!!demo.ips.gateway'
    system_domain: '!!demo.vars.system_domain'

    hostfile-additions:
        127.0.0.1:       localhost.localdomain localhost localhost4.localdomain localhost4
        '::1':           localhost6.localdomain localhost6
        192.168.121.101: infra.demo.com infra ipa.demo.com ipa salt.demo.com salt ldap.demo.com ldap
        192.168.121.103: nexus.demo.com nexus

    ipv6:
        # NOTE ipv6 mode will be overridden for infra servers
        mode: 'disabled'

    classes:
        infra-server-common:
            sysconfig:
                # Nexus
                IPADDR3: '!!demo.ips.nexus'
                PREFIX3: '24'

                # Gitlab
                IPADDR4: '!!demo.ips.gitlab'
                PREFIX4: '24'

                # Gitlab mattermost
                IPADDR5: '!!demo.ips.mattermost'
                PREFIX5: '24'

                # Gitlab pages
                IPADDR6: '!!demo.ips.pages'
                PREFIX6: '24'

                # Gitlab docker registry
                IPADDR7: '!!demo.ips.gitlab-registry'
                PREFIX7: '24'

                # Grafana and Prometheus
                IPADDR8: '!!demo.ips.dashboard'
                PREFIX8: '24'

                # Elasticsearch and Kibana
                IPADDR9: '!!demo.ips.elk'
                PREFIX9: '24'

                # Kubernetes master
                IPADDR10: '!!demo.ips.master'
                PREFIX10: '24'

                # SOEStack docs
                IPADDR11: '!!demo.ips.docs'
                PREFIX11: '24'
        infra-server-netconnected:
            sysconfig:
                # An net-connected server will set the IP address for the gateway on IPADDR2,
                # and the 121.101 address for IPADDR2
                # and the nginx one (currently unused) will be moved to IPADDR12
                # This is because we desire the IP address that can communicate to the gateway,
                # to be the first one on the interface.
                # Nginx frontend / proxy
                IPADDR12: '!!demo.ips.nginx'
                PREFIX12: '24'
        infra-server-isolated:
            sysconfig:
                # An isolated server will set the x.x.121.101 address for IPADDR1
                # and the nginx one (currently unused) will be slotted onto IPADDR2
                # Main IP, infastructure services etc
                IPADDR1: '!!demo.ips.infra'
                PREFIX1: '24'
                # Nginx frontend / proxy
                IPADDR2: '!!demo.ips.nginx'
                PREFIX2: '24'


node_maps:
    replica1:
        roles: 'role-set:secondary-server-node'
    processor2:
        roles: 'role-set:login-processor-node'
    workstation3:
        roles: 'role-set:developer-workstation-node'

