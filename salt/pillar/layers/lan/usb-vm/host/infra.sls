{{ salt.loadtracker.load_pillar(sls,'host infra') }}

deployments:
    gitlab_baremetal:
        gitlab:
            config:
                hostname:     gitlab.demo.com
                # In my demo VM's I have very limited ram available, so need to set this down low
                # The default is that it will use 1/4 of total RAM or so
                postgres_ram: 128MB
    ipa_master:
        testenv-master:
            config:
                passwords: '!!demo.passwords.ipa'

# Override DNS on the infra server
dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo.com
    nameservers:
        dns1:    127.0.0.1
        dns2:    '!!network.gateway'
        dns3:    ''
    search:
        search1: '!!network.system_domain'
        search2: ''
        search3: ''
        
managed-hosts:
    testenv-master:
        infra.demo.com:
            ip:      '!!demo.ips.infra'
            aliases: ipa
            type:    dns

        pxe-client1:
            ip:       '!!demo.ips.pxe-client1'
            mac:      '52:54:00:96:72:f9'
            type:     client
            hostfile:
                - pxe-client1
        pxe-client2:
            ip:       '!!demo.ips.pxe-client2'
            mac:      '52:54:00:b9:b8:d2'
            type:     client
            hostfile:
                - pxe-client2
        wildcard:
            ip:       '!!demo.ips.wildcard'
            type:     dns 
            aliases:  nginx.demo.com nginx wildcard
        nexus:
            ip:       '!!demo.ips.nexus'
            type:     dns 
            # aliases:  nexus
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
    devices:
        # Can't just ignore this device as we need to use PEERDNS=no 
        # to stop stupid NetworkManager overwriting the resolv.conf
        #eth0:
        #    ignore: True 
        # eth0:
        #     inherit:
        #         - no-peerdns
        #         - ethernet
        #         - enabled
        #         - no-defroute
        #         - dhcp
        #         - no-nm-controlled

        eth0:
            inherit:
                - defaults
                - ethernet
                - enabled
                - gateway
                - defroute
                - infra-dns
                - infra-server-common
                - infra-server-isolated

postfix:
    mode: server

layer-host-loaded: {{sls}}

