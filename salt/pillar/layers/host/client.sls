_loaded:
  {{sls}}:

network:
    hostfile-additions: {}
        # 192.168.121.102: wildcard.demo wildcard nginx.demo nginx
        # 192.168.121.103: nexus.demo
        # 192.168.121.104: gitlab.demo gitlab
        # 192.168.121.105: mattermost.demo mattermost
        # 192.168.121.106: pages.demo pages
        # 192.168.121.107: gitlab-registry.demo gitlab-registry
        # 192.168.121.108: grafana.demo grafana prometheus.demo prometheus
        # 192.168.121.109: kibana.demo kibana elasticsearch.demo elasticsearch
        # 192.168.121.110: master.demo master
        
    ipv6:
        # IPA needs ipv6 enabled
        mode: 'disabled'

