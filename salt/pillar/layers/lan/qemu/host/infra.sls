{{ salt.loadtracker.load_pillar(sls,'host infra') }}

# Overrides and data for the demo test soe lan, 
# which is set up on a libvirt virtual network,
# and intended for running vagrant images with two network
# devices ( therefore the eth0 network is left for vagrant
# and the eth1 device is configured as normal)

deployments:
    gitlab_baremetal:
        gitlab:
            config:
                hostname: gitlab.demo.com
                # In my demo vm's I have very limited ram available, so need to set this down low
                # The default is that it will use 1/4 of total RAM or so
                postgres_ram: 128MB
    ipa_master:
        testenv-master:
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
        dns2:    '!!network.gateway'
        dns3:    ''
    search:
        search1: demo.com
        search2: ''
        search3: ''
        
managed-hosts:
    testenv-master:
        infra.demo.com:
            ip:      192.168.121.101
            aliases: ipa
            type:    dns
        pxe-client1:
            ip:       192.168.121.241
            mac:      '52:54:00:96:72:f9'
            type:     client
            hostfile:
                - pxe-client1
        pxe-client2:
            ip:       192.168.121.242
            mac:      '52:54:00:b9:b8:d2'
            type:     client
            hostfile:
                - pxe-client2
        wildcard:
            ip:       192.168.121.102
            type:     dns 
            aliases:  nginx.demo.com nginx wildcard
        nexus:
            ip:       192.168.121.103
            type:     dns 
            aliases:  nexus.demo.com
        gitlab:
            ip:       192.168.121.104
            type:     dns 
            aliases:  gitlab.demo.com
        mattermost.demo.com:
            ip:       192.168.121.105
            type:     dns 
            aliases:  mattermost
        pages.demo.com:
            ip:       192.168.121.106 
            type:     dns
            aliases:  pages
        gitlab-registry.demo.com:
            ip:       192.168.121.107 
            type:     dns
            aliases:  gitlab-registry
        grafana:
            ip:       192.168.121.108
            type:     dns 
            aliases:  prometheus.demo.com grafana prometheus
        kibana:
            ip:       192.168.121.109
            type:     dns 
            aliases:  elasticsearch.demo.com kibana elasticsearch
        master:
            ip:       192.168.121.110
            type:     dns 
            aliases:  master.demo.com master k8s.demo.com k8s
        docs:
            ip:       192.168.121.111
            type:     dns 
            aliases:  docs.demo.com docs

network:
    devices:
        # Can't just ignore this device as we need to use PEERDNS=no 
        # to stop stupid NetworkManager overwriting the resolv.conf
        #eth0:
        #    ignore: True 

        eth0:
            inherit:
                - no-peerdns
                - ethernet
                - enabled
                - no-defroute
                - no-zeroconf
                - no-nm-controlled
                # Vagrant will configure this interface with dhcp
                - dhcp

        eth1:
            inherit:
                - defaults
                - ethernet
                - enabled
                - gateway
                - defroute
                - no-zeroconf
                - no-nm-controlled
                - infra-server
                - infra-dns

layer-host-loaded: {{sls}}


# For now the private layer files are not included, as 
# the USB provisioning has no way currently to include them

#include:
#    - layers.private.gitlab
#    - layers.private.timezone
