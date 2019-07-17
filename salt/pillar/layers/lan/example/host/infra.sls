{{ salt.loadtracker.load_pillar(sls,'host infra') }}

deployments:
    gitlab_baremetal:
        gitlab:
            config:
                hostname: gitlab.demo.com
    ipa_master:
        demo-ipa-master:
            config:
                passwords:
                    master: master123
                    admin:  admin123
                    ds:     random

# Override DNS on the infra server
dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo.com
    nameservers:
        dns1:    127.0.0.1
        dns2:    '!!demo.ips.gateway'   # The internet connected router
        dns3:    ''
    search:
        search1: demo.com
        search2: ''
        search3: ''

managed-hosts:
    demo-ipa-master:
        infra.demo.com:
            ip:      '!!demo.ips.infra'
            aliases: ipa
            type:    dns
        replica1:
            ip:       '!!demo.ips.replica1'
            mac:      '52:54:00:96:72:f9'
            type:     client
            hostfile:
                - replica1
        processor2:
            ip:       '!!demo.ips.processor2'
            mac:      '52:54:00:b9:b8:d2'
            type:     client
            hostfile:
                - processor2
        workstation3:
            ip:       '!!demo.ips.workstation3'
            mac:      '52:54:00:01:02:03'
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
            # aliases:  nexus
        gitlab:
            ip:       '!!demo.ips.gitlab'
            type:     dns 
            aliases:  gitlab
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
