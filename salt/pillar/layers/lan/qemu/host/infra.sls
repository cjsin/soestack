deployment:
    gitlab_baremetal:
        gitlab:
            config:
                hostname: gitlab.qemu

# Override DNS on the infra server

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.qemu
    nameservers:
        dns1:    127.0.0.1
        dns2:    192.168.121.1 # The VM host
        dns3:    ''
    search:
        search1: qemu
        search2: ''
        search3: ''
        
managed-hosts:
    testenv-master:
        infra.qemu:
            ip:      192.168.121.101
            lan:     qemu
            aliases: ipa ipa.qemu
            type:    dns
        pxe-client:
            ip:       192.168.121.250
            mac:      '52:54:00:96:72:f9'
            lan:      qemu
            type:     client
            hostfile:
                - pxe-client
        pxe-client2:
            ip:       192.168.121.251
            mac:      '52:54:00:b9:62:3b'
            lan:      qemu
            type:     client
            hostfile:
                - pxe-client2
        wildcard:
            ip:       192.168.121.102
            type:     dns 
            aliases:  nginx.qemu nginx wildcard
        nexus:
            ip:       192.168.121.103
            type:     dns 
            # aliases:  nexus
        gitlab:
            ip:       192.168.121.104
            type:     dns 
            aliases:   gitlab
        mattermost.qemu:
            ip:       192.168.121.105
            type:     dns 
            aliases:  mattermost
        pages.qemu:
            ip:       192.168.121.106 
            type:     dns
            aliases:  pages
        gitlab-registry.qemu:
            ip:       192.168.121.107 
            type:     dns
            aliases:  gitlab-registry
        grafana:
            ip:       192.168.121.108
            type:     dns 
            aliases:  prometheus.qemu grafana prometheus
        kibana:
            ip:       192.168.121.109
            type:     dns 
            aliases:  elasticsearch.qemu kibana elasticsearch
        master:
            ip:       192.168.121.110
            type:     dns 
            aliases:  master.qemu master k8s.qemu k8s

network:
    devices:
        eth0:
            ignore: True 
        eth1:
            inherit:
                - defaults
                - ethernet
                - enabled
                - gateway
                - defroute
                - infra-server
                - infra-dns
