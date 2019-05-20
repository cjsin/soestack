managed-hosts:
    testenv-client:
        infra:
            ip:       192.168.121.101
            mac:      '52:54:00:d5:19:d5'
            lan:      demo
            aliases:  infra ipa.demo ipa salt.demo salt ldap.demo ldap
            type:     client
            hostfile:
                - '.*'
    testenv-master:
        infra.demo:
            ip:      192.168.121.101
            lan:     demo
            aliases: ipa ipa.demo
            type:    dns
        client:
            ip:       10.0.2.15
            mac:      '52:54:00:c0:ce:8a'
            lan:      qemu
            type:     client
        pxe-client:
            ip:       192.168.121.250
            mac:      '52:54:00:96:72:f9'
            lan:      demo
            type:     client
            hostfile:
                - pxe-client
        pxe-client2:
            ip:       192.168.121.251
            mac:      '52:54:00:b9:62:3b'
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
    