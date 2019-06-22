_loaded:
    {{sls}}:

deployments:
    gitlab_baremetal:
        gitlab:
            config:
                hostname: gitlab.demo

# Override DNS on the infra server
dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo
    nameservers:
        dns1:    127.0.0.1
        dns2:    192.168.188.1   # The internet connected router
        dns3:    ''
    search:
        search1: demo
        search2: ''
        search3: ''

managed-hosts:
    testenv-master:
        infra.demo:
            ip:      192.168.121.101
            lan:     demo
            aliases: ipa ipa.demo
            type:    dns
        pxe-client1:
            ip:       192.168.121.241
            mac:      '52:54:00:96:72:f9'
            lan:      demo
            type:     client
            hostfile:
                - pxe-client1
        pxe-client2:
            ip:       192.168.121.242
            mac:      '52:54:00:b9:b8:d2'
            lan:      demo
            type:     client
            hostfile:
                - pxe-client2
        wildcard:
            ip:       192.168.121.102
            type:     dns 
            aliases:  nginx.demo nginx wildcard
        nexus:
            ip:       192.168.121.103
            type:     dns 
            # aliases:  nexus
        gitlab:
            ip:       192.168.121.104
            type:     dns 
            aliases:   gitlab
        mattermost.demo:
            ip:       192.168.121.105
            type:     dns 
            aliases:  mattermost
        pages.demo:
            ip:       192.168.121.106 
            type:     dns
            aliases:  pages
        gitlab-registry.demo:
            ip:       192.168.121.107 
            type:     dns
            aliases:  gitlab-registry
        grafana:
            ip:       192.168.121.108
            type:     dns 
            aliases:  prometheus.demo grafana prometheus
        kibana:
            ip:       192.168.121.109
            type:     dns 
            aliases:  elasticsearch.demo kibana elasticsearch
        master:
            ip:       192.168.121.110
            type:     dns 
            aliases:  master.demo master k8s.demo k8s
        docs:
            ip:       192.168.121.111
            type:     dns 
            aliases:  docs.usb-vm docs

network:
    devices:
        eth0:
            inherit:
                - defaults
                - ethernet
                - enabled
                - no-peerdns
                - no-zeroconf
                - no-nm-controlled
                - lan-wired-gateway
                - infra-server
                - infra-dns
